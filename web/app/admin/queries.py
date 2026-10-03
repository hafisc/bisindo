"""Query baca untuk halaman admin.

Semua akses data halaman admin ada di file ini. Kalau suatu hari sumber data
pindah (misalnya ke Firestore), cukup ganti isi file ini dan template tidak
perlu disentuh.
"""

from datetime import datetime, timedelta, timezone

from sqlalchemy import desc, func, or_, select
from sqlalchemy.orm import contains_eager

from ..extensions import db
from ..models import DetectionLog, User

WIB = timezone(timedelta(hours=7))

BULAN = ["Jan", "Feb", "Mar", "Apr", "Mei", "Jun", "Jul", "Agu", "Sep", "Okt", "Nov", "Des"]
HARI = ["Sen", "Sel", "Rab", "Kam", "Jum", "Sab", "Min"]


def to_wib(value: datetime) -> datetime:
    """Ubah waktu UTC (tanpa tzinfo) dari database ke WIB."""
    return value.replace(tzinfo=timezone.utc).astimezone(WIB)


def _wib_midnight_as_utc(days_ago: int = 0) -> datetime:
    """Awal hari WIB (n hari lalu) dalam UTC tanpa tzinfo, untuk filter query."""
    today = datetime.now(WIB).replace(hour=0, minute=0, second=0, microsecond=0)
    start = today - timedelta(days=days_ago)
    return start.astimezone(timezone.utc).replace(tzinfo=None)


def get_stats() -> dict:
    total_users = db.session.scalar(select(func.count(User.id))) or 0
    total_logs = db.session.scalar(select(func.count(DetectionLog.id))) or 0
    today_logs = (
        db.session.scalar(
            select(func.count(DetectionLog.id)).where(
                DetectionLog.created_at >= _wib_midnight_as_utc()
            )
        )
        or 0
    )
    avg_confidence = db.session.scalar(select(func.avg(DetectionLog.confidence)))
    return {
        "total_users": total_users,
        "total_logs": total_logs,
        "today_logs": today_logs,
        "avg_confidence": avg_confidence,  # None kalau belum ada log
    }


def get_top_letters(limit: int = 5) -> list[dict]:
    total = func.count(DetectionLog.id)
    rows = db.session.execute(
        select(DetectionLog.letter, total.label("total"))
        .group_by(DetectionLog.letter)
        .order_by(desc("total"), DetectionLog.letter)
        .limit(limit)
    ).all()
    peak = rows[0].total if rows else 0
    return [
        {
            "letter": row.letter,
            "total": row.total,
            "percent": round(row.total / peak * 100) if peak else 0,
        }
        for row in rows
    ]


def get_daily_counts(days: int = 7) -> list[dict]:
    """Jumlah deteksi per hari (WIB) untuk n hari terakhir, termasuk hari ini."""
    start = _wib_midnight_as_utc(days - 1)
    created = db.session.scalars(
        select(DetectionLog.created_at).where(DetectionLog.created_at >= start)
    ).all()

    counts: dict = {}
    for value in created:
        day = to_wib(value).date()
        counts[day] = counts.get(day, 0) + 1

    today = datetime.now(WIB).date()
    series = []
    for offset in range(days - 1, -1, -1):
        day = today - timedelta(days=offset)
        series.append(
            {
                "label": HARI[day.weekday()],
                "date": f"{day.day} {BULAN[day.month - 1]}",
                "total": counts.get(day, 0),
                "is_today": offset == 0,
            }
        )
    peak = max((item["total"] for item in series), default=0)
    for item in series:
        item["percent"] = round(item["total"] / peak * 100) if peak else 0
    return series


def _logs_statement():
    return (
        select(DetectionLog)
        .outerjoin(User, DetectionLog.user_id == User.id)
        .options(contains_eager(DetectionLog.user))
        .order_by(DetectionLog.created_at.desc(), DetectionLog.id.desc())
    )


def get_latest_logs(limit: int = 5) -> list[DetectionLog]:
    return list(db.session.scalars(_logs_statement().limit(limit)).unique())


def paginate_users(search: str, page: int, per_page: int):
    stmt = select(User).order_by(User.created_at.desc(), User.id.desc())
    if search:
        stmt = stmt.where(
            or_(
                User.name.icontains(search, autoescape=True),
                User.email.icontains(search, autoescape=True),
            )
        )
    pagination = db.paginate(stmt, page=page, per_page=per_page, error_out=False)

    # Jumlah deteksi per pengguna, hanya untuk pengguna di halaman ini.
    ids = [user.id for user in pagination.items]
    totals = {}
    if ids:
        totals = dict(
            db.session.execute(
                select(DetectionLog.user_id, func.count(DetectionLog.id))
                .where(DetectionLog.user_id.in_(ids))
                .group_by(DetectionLog.user_id)
            ).all()
        )
    return pagination, totals


def paginate_logs(letter: str, search: str, page: int, per_page: int):
    stmt = _logs_statement()
    if letter:
        stmt = stmt.where(DetectionLog.letter == letter)
    if search:
        stmt = stmt.where(
            or_(
                User.name.icontains(search, autoescape=True),
                User.email.icontains(search, autoescape=True),
            )
        )
    return db.paginate(stmt, page=page, per_page=per_page, error_out=False)


def get_available_letters() -> list[str]:
    return list(
        db.session.scalars(
            select(DetectionLog.letter).distinct().order_by(DetectionLog.letter)
        )
    )

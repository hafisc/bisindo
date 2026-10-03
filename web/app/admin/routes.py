from flask import current_app, flash, redirect, render_template, request, session, url_for

from . import bp, queries
from .auth import check_credentials, login_required, safe_next_url, verify_csrf


def _page_number() -> int:
    return max(request.args.get("page", 1, type=int) or 1, 1)


@bp.get("/")
def index():
    return redirect(url_for("admin.dashboard"))


@bp.route("/login", methods=["GET", "POST"])
def login():
    if session.get("is_admin"):
        return redirect(url_for("admin.dashboard"))

    if request.method == "POST":
        verify_csrf()
        username = request.form.get("username", "").strip()
        password = request.form.get("password", "")
        if check_credentials(username, password):
            session.clear()
            session["is_admin"] = True
            session["admin_name"] = username
            return redirect(safe_next_url(request.args.get("next")))
        flash("Username atau password salah.", "error")

    return render_template("admin/login.html")


@bp.post("/logout")
def logout():
    verify_csrf()
    session.clear()
    flash("Kamu sudah keluar.", "info")
    return redirect(url_for("admin.login"))


@bp.get("/dashboard")
@login_required
def dashboard():
    return render_template(
        "admin/dashboard.html",
        stats=queries.get_stats(),
        top_letters=queries.get_top_letters(),
        daily=queries.get_daily_counts(7),
        latest_logs=queries.get_latest_logs(5),
    )


@bp.get("/users")
@login_required
def users():
    search = request.args.get("q", "").strip()
    pagination, totals = queries.paginate_users(
        search, _page_number(), current_app.config["ADMIN_PER_PAGE"]
    )
    return render_template(
        "admin/users.html", pagination=pagination, totals=totals, search=search
    )


@bp.get("/logs")
@login_required
def logs():
    letter = request.args.get("letter", "").strip().upper()
    search = request.args.get("q", "").strip()
    pagination = queries.paginate_logs(
        letter, search, _page_number(), current_app.config["ADMIN_PER_PAGE"]
    )
    return render_template(
        "admin/logs.html",
        pagination=pagination,
        letter=letter,
        search=search,
        letters=queries.get_available_letters(),
    )

from flask import jsonify, abort
from . import bp

# Data kamus BISINDO (26 huruf)
DICTIONARY_DATA = {
    "A": {"description": "Genggam tangan, ibu jari di samping telunjuk."},
    "B": {"description": "Empat jari rapat tegak, ibu jari melipat di telapak."},
    "C": {"description": "Jari-jari melengkung membentuk huruf C."},
    "D": {"description": "Telunjuk tegak, jari lain melengkung menyentuh ibu jari."},
    "E": {"description": "Semua jari melengkung rapat ke arah telapak."},
    "F": {"description": "Ujung telunjuk dan ibu jari bersentuhan, jari lain tegak."},
    "G": {"description": "Ibu jari dan telunjuk sejajar horizontal."},
    "H": {"description": "Telunjuk dan jari tengah sejajar horizontal."},
    "I": {"description": "Jari kelingking tegak, jari lain menggenggam."},
    "J": {"description": "Jari kelingking membuat gerakan melengkung seperti J."},
    "K": {"description": "Telunjuk dan jari tengah tegak, ibu jari di antara keduanya."},
    "L": {"description": "Telunjuk tegak dan ibu jari lurus horizontal (sudut 90 derajat)."},
    "M": {"description": "Tiga jari (telunjuk, tengah, manis) melipat di atas ibu jari."},
    "N": {"description": "Dua jari (telunjuk, tengah) melipat di atas ibu jari."},
    "O": {"description": "Semua ujung jari bersentuhan membentuk lingkaran."},
    "P": {"description": "Posisi K tetapi mengarah ke bawah."},
    "Q": {"description": "Posisi G tetapi mengarah ke bawah."},
    "R": {"description": "Jari telunjuk dan jari tengah disilangkan."},
    "S": {"description": "Tangan menggenggam, ibu jari di depan jari-jari lain."},
    "T": {"description": "Ibu jari disisipkan di bawah telunjuk yang melipat."},
    "U": {"description": "Telunjuk dan jari tengah rapat tegak."},
    "V": {"description": "Telunjuk dan jari tengah terbuka tegak (membentuk V)."},
    "W": {"description": "Telunjuk, tengah, dan manis terbuka tegak (membentuk W)."},
    "X": {"description": "Telunjuk melengkung seperti kail."},
    "Y": {"description": "Ibu jari dan kelingking terbuka, jari lain melipat."},
    "Z": {"description": "Telunjuk bergerak membentuk pola Z di udara."},
}

@bp.route("/", methods=["GET"])
def get_all_letters():
    """Mengambil seluruh daftar huruf."""
    letters = [{"letter": k} for k in sorted(DICTIONARY_DATA.keys())]
    return jsonify(letters)

@bp.route("/<string:letter>", methods=["GET"])
def get_letter_detail(letter):
    """Mengambil detail satu huruf tertentu."""
    letter = letter.upper()
    if letter not in DICTIONARY_DATA:
        abort(404, description=f"Huruf {letter} tidak ditemukan.")
    
    data = DICTIONARY_DATA[letter].copy()
    data["letter"] = letter
    # Image URL assumes files follow pattern static/img/dictionary/A.png
    data["image_url"] = f"/static/img/dictionary/{letter}.png"
    
    return jsonify(data)

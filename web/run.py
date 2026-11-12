"""Titik masuk server BISINDO.

Dijalankan dengan ``python run.py`` dari folder ``web/``.

Server sengaja mendengarkan di semua antarmuka (``0.0.0.0``) supaya aplikasi
mobile di HP bisa menghubungi laptop lewat WiFi yang sama. Alamat IP jaringan
lokal dicetak saat start, dan alamat itulah yang diisi di layar Scan aplikasi.
"""

import os
import socket

from app import create_app

app = create_app()


def _local_addresses() -> list[str]:
    """Kumpulkan alamat IPv4 non-loopback milik komputer ini.

    Dipakai hanya untuk menampilkan petunjuk di terminal, bukan untuk
    menjalankan server.
    """
    addresses: set[str] = set()

    try:
        for info in socket.getaddrinfo(socket.gethostname(), None, socket.AF_INET):
            addresses.add(info[4][0])
    except OSError:
        pass

    # Cara paling andal menemukan IP yang dipakai untuk keluar jaringan:
    # buka socket UDP lalu lihat alamat lokalnya. Tidak ada paket yang dikirim.
    try:
        probe = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        try:
            probe.connect(("8.8.8.8", 80))
            addresses.add(probe.getsockname()[0])
        finally:
            probe.close()
    except OSError:
        pass

    return sorted(
        address
        for address in addresses
        if not address.startswith("127.") and address != "0.0.0.0"
    )


def _print_banner(host: str, port: int) -> None:
    line = "=" * 64
    print(line)
    print("BISINDO API siap dipakai")
    print(f"  Di komputer ini : http://127.0.0.1:{port}")

    if host in ("0.0.0.0", "::"):
        addresses = _local_addresses()
        if addresses:
            for address in addresses:
                print(f"  Dari HP (WiFi)  : http://{address}:{port}")
            print("")
            print("  Isi salah satu alamat 'Dari HP' di aplikasi mobile:")
            print("  layar Scan, ikon gerigi di kanan atas.")
        else:
            print("  Dari HP         : alamat IP tidak terdeteksi, cek koneksi WiFi")
    elif host.startswith("127.") or host == "localhost":
        print(f"  Server hanya menerima koneksi dari {host}, HP tidak bisa terhubung.")
    else:
        print(f"  Dari HP (WiFi)  : http://{host}:{port}")

    print("  Hentikan dengan Ctrl+C")
    print(line)


if __name__ == "__main__":
    host = os.environ.get("HOST", "0.0.0.0")
    port = int(os.environ.get("PORT", "5000"))
    # Debug bawaan mati: server ini mendengarkan WiFi bersama, dan Werkzeug
    # debugger membuka konsol interaktif ke siapa pun di jaringan itu. Nyalakan
    # hanya saat mengembangkan sendiri: FLASK_DEBUG=1 python run.py
    debug = os.environ.get("FLASK_DEBUG", "0") in ("1", "true", "True")

    _print_banner(host, port)
    app.run(host=host, port=port, debug=debug)

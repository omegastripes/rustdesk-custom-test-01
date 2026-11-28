#!/usr/bin/env python3
"""Patch the hbb_common submodule in CI: FinDesk app name + private server."""

import os
import re
import sys

CONFIG = "libs/hbb_common/src/config.rs"


def fail(msg: str) -> int:
    print(msg, file=sys.stderr)
    return 1


def main() -> int:
    server = os.environ.get("RENDEZVOUS_SERVER", "").strip()
    key = os.environ.get("RS_PUB_KEY", "").strip()
    server = server.split("://", 1)[-1].rstrip("/")
    if not server or not key:
        return fail("RENDEZVOUS_SERVER and RS_PUB_KEY must be set")
    if any(c in server + key for c in '"\\'):
        return fail("RENDEZVOUS_SERVER/RS_PUB_KEY contain characters unsafe for a Rust string literal")

    with open(CONFIG, encoding="utf-8") as f:
        src = f.read()

    src = src.replace('"RustDesk"', '"FinDesk"')

    src, n = re.subn(
        r'(PROD_RENDEZVOUS_SERVER: RwLock<String> = RwLock::new\(")[^"]*("\.to_owned\(\)\))',
        rf"\g<1>{server}\g<2>",
        src,
        count=1,
    )
    if n != 1:
        return fail("PROD_RENDEZVOUS_SERVER pattern not found in hbb_common config.rs")

    src, n = re.subn(
        r'(pub const RENDEZVOUS_SERVERS: &\[&str\] = &\[")[^"]*("\];)',
        rf"\g<1>{server}\g<2>",
        src,
        count=1,
    )
    if n != 1:
        return fail("RENDEZVOUS_SERVERS pattern not found in hbb_common config.rs")

    src, n = re.subn(
        r'(pub const RS_PUB_KEY: &str = ")[^"]*(";)',
        rf"\g<1>{key}\g<2>",
        src,
        count=1,
    )
    if n != 1:
        return fail("RS_PUB_KEY pattern not found in hbb_common config.rs")

    with open(CONFIG, "w", encoding="utf-8") as f:
        f.write(src)
    return 0


if __name__ == "__main__":
    sys.exit(main())

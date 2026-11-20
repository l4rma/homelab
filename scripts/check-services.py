#!/usr/bin/env python3
"""Checks that docs/services/README.md lists every app in kubernetes/apps/.

Fails when a directory in kubernetes/apps/ is not named on the page, or when the
page names a kubernetes/apps/ or kubernetes/infrastructure/ directory that does not
exist. Run by pre-commit (see .pre-commit-config.yaml), from the repository root.
"""

import re
import sys
from pathlib import Path

PAGE = Path("docs/services/README.md")
APPS = Path("kubernetes/apps")
REFERENCE = re.compile(r"`(kubernetes/(?:apps|infrastructure)/[a-z0-9-]+)`")


def main() -> int:
    named = set(REFERENCE.findall(PAGE.read_text(encoding="utf-8")))
    # Only directories Flux would deploy; an empty folder left behind locally is not an app.
    apps = {
        f"{APPS}/{d.name}"
        for d in APPS.iterdir()
        if (d / "kustomization.yaml").is_file()
    }

    errors = [f"{app} is not listed in {PAGE}" for app in sorted(apps - named)] + [
        f"{PAGE} names {path}, which does not exist"
        for path in sorted(named)
        if not Path(path).is_dir()
    ]

    for error in errors:
        print(error, file=sys.stderr)
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())

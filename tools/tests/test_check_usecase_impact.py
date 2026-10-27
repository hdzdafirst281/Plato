from __future__ import annotations

import json
import subprocess
import tempfile
import unittest
from pathlib import Path

from tools.check_usecase_impact import (
    analyze_impact,
    changed_files,
    changed_localization_keys,
)


class CheckUsecaseImpactTest(unittest.TestCase):
    def setUp(self) -> None:
        self.usecases = {
            "UC31": {
                "source": "plato_docs/usecases/UC31.md",
                "code_paths": ["plato_gymapp/lib/example/*.dart"],
                "localization_keys": ["settings.title"],
            }
        }

    def test_code_path_maps_to_use_case(self) -> None:
        impacts, unclassified = analyze_impact(
            self.usecases, ["plato_gymapp/lib/example/screen.dart"]
        )
        self.assertIn("UC31", impacts)
        self.assertEqual(unclassified, [])

    def test_localization_key_maps_to_use_case(self) -> None:
        impacts, unclassified = analyze_impact(
            self.usecases,
            ["plato_gymapp/lib/i18n/strings_vi.i18n.json"],
            {"settings.title"},
        )
        self.assertIn("UC31", impacts)
        self.assertEqual(unclassified, [])

    def test_unknown_application_file_is_reported(self) -> None:
        impacts, unclassified = analyze_impact(
            self.usecases, ["plato_gymapp/lib/other/new.dart"]
        )
        self.assertEqual(impacts, {})
        self.assertEqual(unclassified, ["plato_gymapp/lib/other/new.dart"])

    def test_staged_localization_diff_reads_index_content(self) -> None:
        temp_root = Path.cwd() / ".tmp"
        temp_root.mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(dir=temp_root) as directory:
            repo = Path(directory)
            path = repo / "plato_gymapp/lib/i18n/strings_vi.i18n.json"
            path.parent.mkdir(parents=True)
            path.write_text(json.dumps({"settings": {"title": "Old"}}), encoding="utf-8")
            subprocess.run(["git", "init", "--quiet"], cwd=repo, check=True)
            subprocess.run(["git", "config", "user.name", "Test"], cwd=repo, check=True)
            subprocess.run(
                ["git", "config", "user.email", "test@example.com"], cwd=repo, check=True
            )
            subprocess.run(["git", "add", "."], cwd=repo, check=True)
            subprocess.run(["git", "commit", "--quiet", "-m", "base"], cwd=repo, check=True)
            path.write_text(json.dumps({"settings": {"title": "New"}}), encoding="utf-8")
            subprocess.run(["git", "add", "."], cwd=repo, check=True)

            files = changed_files(repo, staged=True, base=None)
            keys = changed_localization_keys(repo, files, staged=True, base=None)
            self.assertEqual(keys, {"settings.title"})


if __name__ == "__main__":
    unittest.main()


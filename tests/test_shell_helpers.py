"""Run with python -m unittest discover -s tests -p test_shell_helpers.py."""

import os
from pathlib import Path
import shlex
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = ROOT / "bash"


class ShellChecks:
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.env = dict(
            os.environ, GIT_CONFIG_GLOBAL=os.devnull, GIT_CONFIG_NOSYSTEM="1"
        )
        self.env.update(
            GIT_AUTHOR_NAME="Test",
            GIT_AUTHOR_EMAIL="test@example.com",
            GIT_COMMITTER_NAME="Test",
            GIT_COMMITTER_EMAIL="test@example.com",
        )
        self.remote = self.root / "remote.git"
        self.repo = self.root / "main checkout"
        self.git(self.root, "init", "--bare", "--initial-branch=main", self.remote)
        self.git(self.root, "clone", self.remote, self.repo)
        self.commit(self.repo, "shared", "base\n")
        self.git(self.repo, "push", "-u", "origin", "main")
        self.main_before = self.sha(self.repo)
        self.wt = self.feature("simon/a", "a worktree")
        self.before = self.sha(self.wt)
        self.commit(self.repo, "upstream", "new main\n")
        self.git(self.repo, "push", "origin", "main")
        self.base = self.sha(self.repo)
        self.git(self.repo, "reset", "--hard", self.main_before)

    def git(self, cwd, *args, check=True):
        return subprocess.run(
            ["git", *map(str, args)],
            cwd=cwd,
            env=self.env,
            text=True,
            capture_output=True,
            check=check,
        )

    def sha(self, cwd, ref="HEAD"):
        return self.git(cwd, "rev-parse", ref).stdout.strip()

    def commit(self, cwd, name, content):
        (cwd / name).write_text(content)
        self.git(cwd, "add", name)
        self.git(cwd, "commit", "-m", name)

    def feature(self, branch, folder):
        wt = self.root / folder
        self.git(self.repo, "worktree", "add", "--no-track", "-b", branch, wt, "main")
        self.commit(wt, folder + ".txt", branch + "\n")
        self.git(wt, "push", "-u", "origin", branch)
        return wt

    def shell(self, code, cwd=None):
        return subprocess.run(
            [self.shell_name, "-fc", code],
            cwd=cwd or self.repo,
            env=self.env,
            text=True,
            capture_output=True,
        )

    def run_helper(self, cwd=None):
        return self.shell(
            f"source {shlex.quote(str(SCRIPTS / 'git.sh'))}\ngitrebaseworktrees", cwd
        )

    def assert_stopped(self, result, text):
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn(text, result.stderr)
        self.assertEqual(self.sha(self.wt), self.before)
        self.assertEqual(self.sha(self.remote, "simon/a"), self.before)

    def test_rebase_push_and_repeat_from_subdirectory(self):
        later = self.feature("simon/z", "z worktree")
        # User config must not move other refs or publish tags along with the target branch.
        self.git(self.repo, "config", "rebase.updateRefs", "true")
        self.git(self.repo, "config", "push.followTags", "true")
        self.git(self.repo, "config", "remote.origin.mirror", "true")
        self.git(self.repo, "branch", "someone/untouched", "simon/a")
        self.git(self.repo, "tag", "-a", "local-only", "-m", "local", "main")
        self.git(self.wt, "config", "rebase.autoStash", "true")
        main_line = (
            f"{self.repo}: fetching origin\n"
            f"{self.repo} (main): skipped main checkout\n"
            f"{self.wt} (simon/a): checking\n"
            f"{later} (simon/z): checking\n"
        )
        nested = self.wt / "nested"
        nested.mkdir()
        result = self.run_helper(nested)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(
            result.stdout,
            main_line
            + f"{self.wt} (simon/a): rebasing onto origin/main\n"
            + f"{self.wt} (simon/a): pushing to origin/simon/a\n"
            + f"{self.wt} (simon/a): updated and pushed\n"
            + f"{later} (simon/z): rebasing onto origin/main\n"
            + f"{later} (simon/z): pushing to origin/simon/z\n"
            + f"{later} (simon/z): updated and pushed\n",
        )
        self.assertEqual(self.sha(later), self.sha(self.remote, "simon/z"))
        self.git(later, "merge-base", "--is-ancestor", self.base, "HEAD")
        after = self.sha(self.wt)
        self.assertNotEqual(after, self.before)
        self.assertEqual(self.sha(self.remote, "simon/a"), after)
        self.git(self.wt, "merge-base", "--is-ancestor", self.base, after)
        self.assertEqual(self.sha(self.repo), self.main_before)
        self.assertEqual(self.sha(self.repo, "someone/untouched"), self.before)
        self.assertNotEqual(
            self.git(
                self.remote,
                "rev-parse",
                "--verify",
                "refs/tags/local-only",
                check=False,
            ).returncode,
            0,
        )
        again = self.run_helper()
        self.assertEqual(again.returncode, 0, again.stdout + again.stderr)
        self.assertEqual(self.sha(self.wt), after)
        self.assertEqual(
            again.stdout,
            main_line
            + f"{self.wt} (simon/a): up to date\n"
            + f"{later} (simon/z): up to date\n",
        )
        self.assertEqual(again.stderr, "")

    def test_no_worktrees_reports_nothing_to_rebase(self):
        self.git(self.repo, "worktree", "remove", self.wt)
        result = self.run_helper()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(
            result.stdout,
            f"{self.repo}: fetching origin\n"
            f"{self.repo} (main): skipped main checkout\nno worktrees to rebase\n",
        )
        self.assertEqual(result.stderr, "")

    def test_foreign_worktree_stops_before_any_rebase(self):
        self.feature("someone/z", "z worktree")
        self.assert_stopped(self.run_helper(), "does not start with simon/")

    def test_foreign_primary_checkout_stops(self):
        self.git(self.repo, "checkout", "-b", "someone/main")
        self.assert_stopped(self.run_helper(), "does not start with simon/")

    def test_detached_worktree_stops(self):
        self.git(
            self.repo, "worktree", "add", "--detach", self.root / "z detached", "main"
        )
        self.assert_stopped(self.run_helper(), "detached")

    def test_dirty_later_worktree_stops_before_any_rebase(self):
        later = self.feature("simon/z", "z worktree")
        (later / "untracked").write_text("keep me")
        self.assert_stopped(self.run_helper(), "changes or untracked files")
        self.assertEqual((later / "untracked").read_text(), "keep me")

    def test_wrong_upstream_stops(self):
        self.git(self.wt, "branch", "--set-upstream-to=origin/main")
        self.assert_stopped(self.run_helper(), "must track origin/simon/a")

    def test_missing_remote_stops(self):
        self.git(self.repo, "push", "origin", "--delete", "simon/a")
        result = self.run_helper()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn(f"{self.wt} (simon/a): checking", result.stdout)
        self.assertIn(
            f"stop: {self.wt} (simon/a): origin/simon/a is missing", result.stderr
        )
        self.assertNotIn("fatal:", result.stderr)
        self.assertNotIn("rebasing", result.stdout)
        self.assertNotIn("pushing", result.stdout)
        self.assertEqual(self.sha(self.wt), self.before)
        self.assertNotEqual(
            self.git(
                self.remote, "rev-parse", "--verify", "refs/heads/simon/a", check=False
            ).returncode,
            0,
        )

    def test_missing_main_names_repository(self):
        self.git(self.remote, "update-ref", "-d", "refs/heads/main")
        result = self.run_helper()
        self.assert_stopped(result, f"stop: {self.repo}: origin/main is missing")
        self.assertNotIn("fatal:", result.stderr)

    def test_remote_ahead_stops(self):
        other = self.root / "other"
        self.git(self.root, "clone", "-b", "simon/a", self.remote, other)
        self.commit(other, "remote", "new remote\n")
        self.git(other, "push")
        remote_head = self.sha(other)
        result = self.run_helper()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("commits missing locally", result.stderr)
        self.assertEqual(self.sha(self.wt), self.before)
        self.assertEqual(self.sha(self.remote, "simon/a"), remote_head)

    def test_operation_in_progress_stops(self):
        gitdir = Path(
            self.git(self.wt, "rev-parse", "--absolute-git-dir").stdout.strip()
        )
        (gitdir / "rebase-merge").mkdir()
        self.assert_stopped(self.run_helper(), "operation in progress")

    def test_different_push_url_stops(self):
        self.git(
            self.repo, "config", "remote.origin.pushurl", str(self.root / "elsewhere")
        )
        self.assert_stopped(self.run_helper(), "matching fetch/push URL")

    def test_conflict_stops_without_pushing_or_touching_next_worktree(self):
        self.commit(self.wt, "shared", "feature version\n")
        self.git(self.wt, "push")
        before_conflict = self.sha(self.wt)
        later = self.feature("simon/z", "z worktree")
        later_head = self.sha(later)
        self.commit(self.repo, "shared", "main version\n")
        self.git(self.repo, "push", "--force", "origin", "main")
        result = self.run_helper()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("rebase failed", result.stderr)
        self.assertEqual(self.sha(self.remote, "simon/a"), before_conflict)
        self.assertEqual(self.sha(later), later_head)
        self.assertEqual(self.sha(self.remote, "simon/z"), later_head)
        self.assertIn("UU shared", self.git(self.wt, "status", "--porcelain").stdout)

    def test_fixed_lease_rejects_concurrent_push_even_after_background_fetch(self):
        other = self.root / "other"
        self.git(self.root, "clone", "-b", "simon/a", self.remote, other)
        self.commit(other, "concurrent", "remote update\n")
        concurrent = self.sha(other)
        hook = self.repo / ".git" / "hooks" / "pre-rebase"
        hook.write_text(
            "#!/bin/sh\nunset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX\n"
            + shlex.join(["git", "-C", str(other), "push", "--quiet"])
            + "\n"
            + shlex.join(["git", "-C", str(self.repo), "fetch", "--quiet", "origin"])
            + "\n"
        )
        hook.chmod(0o755)
        result = self.run_helper()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("push failed", result.stderr)
        self.assertEqual(self.sha(self.remote, "simon/a"), concurrent)
        self.assertNotEqual(self.sha(self.wt), self.before)

    def test_archwhich_function_alias_builtin_and_missing(self):
        source = f"source {shlex.quote(str(SCRIPTS / 'arch.sh'))}\nsource {shlex.quote(str(SCRIPTS / 'git.sh'))}\n"
        result = self.shell(source + "archwhich gitprunebranches")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("git.sh", result.stdout)
        self.assertIn("gitprunebranches", result.stdout)
        self.assertIn("git fetch --all --prune", result.stdout)
        self.assertNotIn("owner:", result.stdout)
        result = self.shell(source + "archwhich gfe")
        self.assertEqual(result.returncode, 0)
        self.assertIn("git fetch -p", result.stdout)
        self.assertNotIn("owner:", result.stdout)
        result = self.shell(source + "archwhich cd")
        self.assertEqual(result.returncode, 0)
        self.assertIn("builtin", result.stdout)
        result = self.shell(source + "archwhich this_command_does_not_exist")
        self.assertEqual(result.returncode, 127)

    def test_archwhich_external_keeps_package_lookup(self):
        bin_dir = self.root / "bin"
        bin_dir.mkdir()
        for name, body in {
            "test-executable": "exit 0",
            "pacman": 'case "$1" in -Qo) echo "$3 is owned by testpkg 1";; -Si) echo "Repository : testrepo";; -Qi) echo "Install Date : today";; esac',
        }.items():
            executable = bin_dir / name
            executable.write_text("#!/bin/sh\n" + body + "\n")
            executable.chmod(0o755)
        self.env["PATH"] = str(bin_dir) + os.pathsep + self.env["PATH"]
        result = self.shell(
            f"source {shlex.quote(str(SCRIPTS / 'arch.sh'))}\narchwhich test-executable"
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("package: testpkg", result.stdout)
        self.assertIn("repo:    testrepo", result.stdout)


class BashChecks(ShellChecks, unittest.TestCase):
    shell_name = "bash"


class ZshChecks(ShellChecks, unittest.TestCase):
    shell_name = "zsh"


if __name__ == "__main__":
    unittest.main()

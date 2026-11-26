"""Tests for the pure helpers in bin/endo-watch.  Run: python3 tools/test_endo_watch.py"""
import importlib.machinery
import importlib.util
import os
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
_loader = importlib.machinery.SourceFileLoader("endo_watch", os.path.join(HERE, "..", "bin", "endo-watch"))
_spec = importlib.util.spec_from_loader("endo_watch", _loader)
ew = importlib.util.module_from_spec(_spec)
_loader.exec_module(ew)


class Helpers(unittest.TestCase):
    def test_write_flags(self):
        self.assertTrue(ew.is_write_flags("0100001"))   # O_WRONLY|O_LARGEFILE
        self.assertTrue(ew.is_write_flags("02"))        # O_RDWR
        self.assertFalse(ew.is_write_flags("0100000"))  # read only

    def test_urls_in(self):
        argv = ["curl", "-L", "-o", "f.gguf", "https://h.co/a/f.gguf", "-H", "X: y"]
        self.assertEqual(ew.urls_in(argv), ["https://h.co/a/f.gguf"])
        self.assertEqual(ew.urls_in(["curl", "https:/bad"]), [])

    def test_pick_url(self):
        self.assertEqual(ew.pick_url(["https://x/y"], "/tmp/anything"), "https://x/y")
        urls = ["https://x/a.iso?t=1", "https://x/b.iso"]
        self.assertEqual(ew.pick_url(urls, "/home/u/a.iso"), "https://x/a.iso?t=1")
        self.assertIsNone(ew.pick_url(urls, "/home/u/c.iso"))

    def test_choose_outputs(self):
        # curl -o file, with stdout/stderr redirected to a log
        self.assertEqual(ew.choose_outputs([(1, "/l.log"), (2, "/l.log"), (5, "/f.bin")]), ["/f.bin"])
        # curl URL > file.bin
        self.assertEqual(ew.choose_outputs([(1, "/f.bin")]), ["/f.bin"])
        # stderr alone is never a download
        self.assertEqual(ew.choose_outputs([(2, "/err.log")]), [])

    def test_parse_total(self):
        self.assertEqual(ew.parse_total({"Content-Range": "bytes 0-0/21712409824"}), 21712409824)
        self.assertEqual(ew.parse_total({"Content-Length": "1234"}), 1234)
        self.assertIsNone(ew.parse_total({"Content-Range": "bytes 0-0/*"}))
        self.assertIsNone(ew.parse_total({}))


if __name__ == "__main__":
    unittest.main()

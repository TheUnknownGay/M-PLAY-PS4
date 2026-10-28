#!/usr/bin/env python3
import argparse
import datetime
from xml.sax.saxutils import quoteattr


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", required=True)
    parser.add_argument("--content-id", required=True)
    parser.add_argument("files", nargs="+")
    args = parser.parse_args()
    paths = [item.replace("\\", "/") for item in args.files]
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    output = [
        '<?xml version="1.0"?>',
        '<psproject xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" fmt="gp4" version="1000">',
        "\t<volume>",
        "\t\t<volume_type>pkg_ps4_app</volume_type>",
        "\t\t<volume_id>PS4VOLUME</volume_id>",
        "\t\t<volume_ts>%s</volume_ts>" % timestamp,
        '\t\t<package content_id=%s passcode="00000000000000000000000000000000" storage_type="digital50" app_type="full" />' % quoteattr(args.content_id),
        '\t\t<chunk_info chunk_count="1" scenario_count="1">',
        "\t\t\t<chunks>",
        '\t\t\t\t<chunk id="0" layer_no="0" label="Chunk #0" />',
        "\t\t\t</chunks>",
        "\t\t\t<scenarios>",
        '\t\t\t\t<scenario id="0" type="sp" initial_chunk_count="1" label="Scenario #0">0</scenario>',
        "\t\t\t</scenarios>",
        "\t\t</chunk_info>",
        "\t</volume>",
        '\t<files img_no="0">',
    ]
    for path in paths:
        output.append("\t\t<file targ_path=%s orig_path=%s />" % (quoteattr(path), quoteattr(path)))
    output.extend(["\t</files>", "\t<rootdir>"])
    parents = {}
    for path in paths:
        node = parents
        parts = path.split("/")
        for part in parts[:-1]:
            node = node.setdefault(part, {})
        node[parts[-1]] = None

    def emit_tree(node, depth):
        for name in sorted(node):
            pad = "\t" * depth
            if isinstance(node[name], dict):
                output.append("%s<dir targ_name=%s>" % (pad, quoteattr(name)))
                emit_tree(node[name], depth + 1)
                output.append("%s</dir>" % pad)
            else:
                output.append("%s<dir targ_name=%s />" % (pad, quoteattr(name)))

    emit_tree(parents, 2)
    output.extend(["\t</rootdir>", "</psproject>"])
    with open(args.out, "w", newline="\n", encoding="utf-8") as handle:
        handle.write("\n".join(output) + "\n")


if __name__ == "__main__":
    main()

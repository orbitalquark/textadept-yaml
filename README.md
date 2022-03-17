# YAML

The YAML module for Textadept.
It provides utilities for editing YAML documents.

## Compiling

Releases include binaries, so building this modules should not be necessary. If you want
to build manually, run `make deps` followed by `make yaml.so`. This assumes the module is
installed in Textadept's *modules/* directory. If it is not (e.g. it is in your `_USERHOME`),
run `make ta=/path/to/textadept yaml.so`.

## Key Bindings

+ `Ctrl+&` (`⌘&` | `M-&`)
  Jump to the anchor for the alias under the caret.

## Functions defined by `_M.yaml`

<a id="_M.yaml.goto_anchor"></a>
### `_M.yaml.goto_anchor`()

Jumps to the anchor for the alias underneath the caret.


---

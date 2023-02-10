# ips-patcher.hy
A simple [IPS](https://zerosoft.zophar.net/ips.php) patcher written in Hy

## Usage
Simply run the patcher from the command line, providing it with a ROM file to
patch and an IPS file containing the patches. Optionally you can provide the
path where to save the resulting ROM file. If the path for the output file is
ommited, the resulting file will be named `[original rom name] - [IPS
name].[original ROM extension]`

```
$ ips-patcher <path/to/ROM> <path/to/IPS> [<path/to/output>]
```


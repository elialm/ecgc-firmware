from argparse import ArgumentParser
import re

_POSTFIX_REMOVE_PATTERN = re.compile(r'(\w+)_([IO]+)')

def convert_port_name(original: str, match_object: re.Match):
    match match_object.group(2):
        case 'in':
            prefix = 'i_'
        case 'out':
            prefix = 'o_'
        case 'inout':
            prefix = 'io_'
    
    if m := re.match(_POSTFIX_REMOVE_PATTERN, original):
        return prefix + m.group(1).lower()
    else:
        return prefix + original.lower()
    
def convert_signal_name(original: str, match_object: re.Match):
    return 'n_' + original.lower()

_PATTERNS = (
    {
        'group': 1,
        'pattern': re.compile(r'(\w+)\s*:\s*(in|out|inout)'),
        'conversion_function': convert_port_name
    },
    {
        'group': 2,
        'pattern': re.compile(r'(signal|constant)\s+(\w+)'),
        'conversion_function': convert_signal_name
    }
)

def handle_file(filename: str):
    name_candidates = []
    
    with open(filename, 'r') as src_file:
        for line in src_file:
            line = line.replace('\n', '').replace('\r', '')

            for pattern_meta in _PATTERNS:
                if match := re.search(pattern_meta['pattern'], line):
                    name = match.group(pattern_meta['group'])
                    name_candidates.append({
                        'original_name': name,
                        'converted_name': pattern_meta['conversion_function'](name, match)
                    })
                    break

    for candidate in name_candidates:
        print('s/{}/{}/g'.format(candidate['original_name'], candidate['converted_name']))

def main_cli():
    parser = ArgumentParser(prog='name_conversion', description='Script for converting variable names from old to new format and generating sed commands to do said conversion')
    parser.add_argument('file', help='Input VHDL file')

    args = parser.parse_args()

    handle_file(args.file)

if __name__ == '__main__':
    main_cli()
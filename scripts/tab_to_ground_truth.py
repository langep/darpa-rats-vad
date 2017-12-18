#!/usr/bin/env python
import sys
import os
from decimal import Decimal


mapping = {'NS': '0', 'S': '1', 'NT': '2', 'RX': '-1', 'RS': '-2', 'RI': '-3'}

if __name__ == '__main__':
    tab_filename = sys.argv[1]
    output_path = sys.argv[2]
    output_name = sys.argv[3]
    output_filename = output_name + '.ground_truth'
    ground_truth = []
    with open(tab_filename, 'r') as fh:
        for line in fh.readlines():
            cols = line.split()
            target = mapping[cols[4]]
            start = Decimal(float(cols[2]))
            end = Decimal(float(cols[3]))
            # Round to frame-shift precision (10ms)
            # Multiply by 100 to convert to frame number
            # inclusive end
            start_frame = int(round(start, 2) * 100)
            # Exclusive end
            end_frame = int(round(end, 2) * 100)
            segment_length = end_frame - start_frame
            ground_truth += [str(target)] * segment_length
    with open(os.path.join(output_path, output_filename), 'w') as fh:
        fh.write(" ".join(ground_truth))

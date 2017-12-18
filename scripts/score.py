#!/usr/bin/env python
import sys
import os
from glob import glob

full_mapping = {'NS': '0', 'S': '1', 'NT': '2', 'RX': '-1', 'RS': '-2', 'RI': '-3'}
ignore_rx_rs_ri = {'NS': '0', 'S': '1', 'NT': '2'}


def read_targets(path_to_ground_truth_file):
    with open(path_to_ground_truth_file, 'r') as fh:
        line = fh.readline()
        line = line.rstrip()
        targets = line.split()
        return targets


def compute_stats(matrix, mapping):
    total = 0
    correct = 0
    for key in mapping.keys():
        for value in mapping.values():
            total += matrix[mapping[key]][value]
            if mapping[key] == value:
                correct += matrix[mapping[key]][value]
    accuracy = float(correct)/total * 100
    return (total, correct, accuracy)


def print_confusion_matrix(matrix):
    matrix2 = matrix
    print("\t" + "\t".join(full_mapping.keys()))
    lines = []
    for key in full_mapping.keys():
        line = [key]
        for value in full_mapping.values():
            line.append(str(matrix[str(full_mapping[key])][value]))
        lines.append(line)

    for line in lines:
        print("\t".join(line))

    print()
    total, correct, accuracy = compute_stats(matrix, full_mapping)
    print("Total: {0}, Correct: {1}, Accuracy: {2}".format(total, correct, accuracy))
    total_rx, correct_rx, accuracy_rx = compute_stats(matrix, ignore_rx_rs_ri)
    print()
    print("Ignoring RX/RS/RI")
    print("Total: {0}, Correct: {1}, Accuracy: {2}".format(total_rx, correct_rx, accuracy_rx))


def merge_nt_and_ns(matrix):
    matrix2 = dict(matrix)
    for key in matrix2:
        matrix2[key]['0'] += matrix2[key]['2']
        matrix2[key]['2'] = 0
    for key in matrix2['0']:
        matrix2['0'][key] += matrix2['2'][key]
        matrix2['2'][key] = 0
    return matrix2

if __name__ == '__main__':
    ground_truth_dir = sys.argv[1]
    exp_dir = sys.argv[2]
    hypotheses_files = glob(os.path.join(exp_dir, 'vad_gmm_*.ark'))

    confusion_matrix = {
        '0': {'0': 0, '1': 0, '2': 0, '-1': 0, '-2': 0, '-3': 0},
        '1': {'0': 0, '1': 0, '2': 0, '-1': 0, '-2': 0, '-3': 0},
        '2': {'0': 0, '1': 0, '2': 0, '-1': 0, '-2': 0, '-3': 0},
        '-1': {'0': 0, '1': 0, '2': 0, '-1': 0, '-2': 0, '-3': 0},
        '-2': {'0': 0, '1': 0, '2': 0, '-1': 0, '-2': 0, '-3': 0},
        '-3': {'0': 0, '1': 0, '2': 0, '-1': 0, '-2': 0, '-3': 0}
    }

    for file in hypotheses_files:
        with open(file, 'r') as fh:
            for line in fh.readlines():
                parts = line.rstrip().partition(' ')
                utterance_name = parts[0]
                ground_truth_name = utterance_name + '.ground_truth'
                hypotheses = parts[2]
                hypotheses = hypotheses.replace('[ ', '')
                hypotheses = hypotheses.replace(' ]', '')
                hypotheses = hypotheses.split()
                targets = read_targets(os.path.join(ground_truth_dir, ground_truth_name))
                for i, h in enumerate(hypotheses):
                    try:
                        t = targets[i]
                    except:
                        continue
                    confusion_matrix[t][h] += 1

    print_confusion_matrix(confusion_matrix)
    confusion_matrix2 = merge_nt_and_ns(confusion_matrix)
    print()
    print("Combined NS and NT:")
    print_confusion_matrix(confusion_matrix2)

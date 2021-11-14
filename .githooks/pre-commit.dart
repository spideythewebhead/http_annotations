import 'dart:convert';
import 'dart:io';

void main(List<String> args) async {
  final process = await Process.start('dart', ['analyze']);

  String lastLine = '';

  process.stdout.transform(Utf8Decoder()).transform(LineSplitter()).listen(
    (line) {
      lastLine = line;
    },
    onDone: () async {
      if (lastLine == 'No issues found!') {
        print('analyzer passed!');
        exit(0);
      }

      final errors = int.tryParse(lastLine.split(' ').first);

      stdout.writeln('analyzer has found $errors problems, please fix to continue the commit');

      exit(1);
    },
  );
}

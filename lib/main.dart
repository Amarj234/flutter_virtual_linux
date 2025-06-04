import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LinuxVMConsole(),
    );
  }
}

class LinuxVMConsole extends StatefulWidget {
  const LinuxVMConsole({super.key});

  @override
  State<LinuxVMConsole> createState() => _LinuxVMConsoleState();
}

class _LinuxVMConsoleState extends State<LinuxVMConsole> {
  final List<String> output = [];
  Process? qemuProcess;

  @override
  void initState() {
    super.initState();
    prepareAndLaunchQemu();
  }

  @override
  void dispose() {
    qemuProcess?.kill();
    super.dispose();
  }

  Future<String> extractAssetToFile(String assetPath, String filename) async {
    final directory = await getApplicationSupportDirectory();
    final filePath = '${directory.path}/$filename';

    final file = File(filePath);

    if (!await file.exists()) {
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();
      await file.writeAsBytes(bytes, flush: true);
      if (filename.contains('qemu-system')) {
        // Make executable
        await Process.run('chmod', ['+x', filePath]);
      }
    }

    return filePath;
  }

  Future<void> prepareAndLaunchQemu() async {
    setState(() {
      output.clear();
      output.add('Extracting QEMU and disk image...');
    });

    try {
      final qemuPath = await extractAssetToFile('assets/qemu/qemu-system-x86_64', 'qemu-system-x86_64');
      final diskPath = await extractAssetToFile('assets/alpine_disk.img', 'alpine_disk.img');

      setState(() {
        output.add('QEMU path: $qemuPath');
        output.add('Disk path: $diskPath');
      });

      qemuProcess = await Process.start(
        qemuPath,
        [
          '-hda',
          diskPath,
          '-m',
          '512M',
          '-nographic',
          '-serial',
          'mon:stdio',
          '-boot',
          'c',
        ],
        runInShell: true,
      );

      qemuProcess!.stdout.transform(SystemEncoding().decoder).listen((data) {
        setState(() {
          output.add(data);
        });
      });

      qemuProcess!.stderr.transform(SystemEncoding().decoder).listen((data) {
        setState(() {
          output.add('[stderr] $data');
        });
      });

      qemuProcess!.exitCode.then((code) {
        setState(() {
          output.add('QEMU exited with code $code');
        });
      });
    } catch (e) {
      setState(() {
        output.add('Error: $e');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Linux VM')),
      body: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(10),
        child: ListView.builder(
          itemCount: output.length,
          itemBuilder: (context, index) {
            print(output);
            return SelectableText(
            output[index],
            style: const TextStyle(
              color: Colors.greenAccent,
              fontFamily: 'Courier',
              fontSize: 12,
            ),
          );}
        ),
      ),
    );
  }
}

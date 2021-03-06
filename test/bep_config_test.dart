part of syncthing.bep_test;

void runConfigTests() {
  group('Cluster config message', () {
    // Message header and length
    List<int> serialized = [
      0x08, 0xC2, 0x00, 0x00,
      0x00, 0x00, 0x00, 0xB8,
    ];

    serialized.addAll([
      // Length of client name
      0x00, 0x00, 0x00, 0x04,
      // Client name ("test")
      0x74, 0x65, 0x73, 0x74,
      // Length of client version
      0x00, 0x00, 0x00, 0x06,
      // Client version ("v1.2.5")
      0x76, 0x31, 0x2E, 0x32,
      0x2E, 0x35, 0x00, 0x00,
    ]);

    // Folders
    serialized.addAll([
      // Folders length header
      0x00, 0x00, 0x00, 0x02,

      // Folder #1
      // ID length header
      0x00, 0x00, 0x00, 0x06,
      // ID ("sample")
      0x73, 0x61, 0x6D, 0x70,
      0x6C, 0x65, 0x00, 0x00,
      // Devices length header
      0x00, 0x00, 0x00, 0x00,

      // Folder #2
      // ID length header
      0x00, 0x00, 0x00, 0x08,
      // ID ("multiple")
      0x6D, 0x75, 0x6C, 0x74,
      0x69, 0x70, 0x6C, 0x65,
      // Devices length header
      0x00, 0x00, 0x00, 0x01,
      // Device #1
      // ID length header
      0x00, 0x00, 0x00, 0x20,
      // ID data
      0x7F, 0x7C, 0x87, 0x23,
      0xEC, 0xCA, 0x5B, 0x4D,
      0x22, 0x06, 0x1C, 0x49,
      0x81, 0xB3, 0x4C, 0x34,
      0xD8, 0x65, 0xEC, 0x37,
      0x6B, 0xE1, 0xEB, 0x74,
      0x33, 0x08, 0x73, 0xC9,
      0xA6, 0xF9, 0xB2, 0x05,
      // Flags
      0x00, 0x01, 0x00, 0x05,
      // Max local version
      0xF0, 0xE1, 0xD2, 0xC3,
      0xB4, 0xA5, 0x96, 0x87,
    ]);

    // Options
    serialized.addAll([
      // Options length header
      0x00, 0x00, 0x00, 0x03,

      // Option #1
      // Key length header
      0x00, 0x00, 0x00, 0x0A,
      // Key ("customFlag")
      0x63, 0x75, 0x73, 0x74,
      0x6F, 0x6D, 0x46, 0x6C,
      0x61, 0x67, 0x00, 0x00,
      // Value length header
      0x00, 0x00, 0x00, 0x07,
      // Value ("enabled")
      0x65, 0x6E, 0x61, 0x62,
      0x6C, 0x65, 0x64, 0x00,

      // Option #2
      // Key length header
      0x00, 0x00, 0x00, 0x0C,
      // Key ("secretOption")
      0x73, 0x65, 0x63, 0x72,
      0x65, 0x74, 0x4F, 0x70,
      0x74, 0x69, 0x6F, 0x6E,
      // Value length header
      0x00, 0x00, 0x00, 0x08,
      // Value ("disabled")
      0x64, 0x69, 0x73, 0x61,
      0x62, 0x6C, 0x65, 0x64,

      // Option #3
      // Key length header
      0x00, 0x00, 0x00, 0x04,
      // Key ("mode")
      0x6D, 0x6F, 0x64, 0x65,
      // Value length header
      0x00, 0x00, 0x00, 0x06,
      // Value ("RANDOM")
      0x52, 0x41, 0x4E, 0x44,
      0x4F, 0x4D, 0x00, 0x00,
    ]);

    String idString = 'P56IOI7-MZJNU2Y-IQGDREY-DM2MGTI-MGL3BXN-PQ6W5BM-TBBZ4TJ-XZWICQ2';

    // Make sure messages can be parsed from immutable lists.
    serialized = new List.from(serialized, growable: false);

    test('can serialize to buffer', () {
      BlockMessage message = new BlockMessage(
          0x8C2,
          new ClusterConfig(
            new XdrString('test'),
            new XdrString('v1.2.5'),
            [
              new Folder(
                new XdrString('sample'),
                []
              ),
              new Folder(
                new XdrString('multiple'),
                [
                  new Device(
                    new DeviceId(idString),
                    new DeviceFlags(
                      priority: DeviceFlags.PRIORITY_HIGH,
                      introducer: true,
                      trusted: true
                    ),
                    new Hyper.forValue(0xF0E1D2C3, 0xB4A59687)
                  )
                ]
              )
            ],
            [
              new Option(
                new XdrString('customFlag'),
                new XdrString('enabled')
              ),
              new Option(
                new XdrString('secretOption'),
                new XdrString('disabled')
              ),
              new Option(
                new XdrString('mode'),
                new XdrString('RANDOM')
              )
            ]
          )
      );

      Uint8List data = new Uint8List.view(message.toBuffer());
      expect(data, equals(serialized));
    });

    test('can deserialize from buffer', () {
      BlockMessage message = new BlockMessage.fromBytes(serialized);
      BlockPayload payload = message.payload;
      expect(payload, isNotNull);
      expect(payload, new isInstanceOf<ClusterConfig>());

      ClusterConfig config = payload as ClusterConfig;
      expect(config.clientName.value, equals('test'));
      expect(config.clientVersion.value, equals('v1.2.5'));

      List<Folder> folders = config.folders;
      expect(folders.length, equals(2));

      Folder folder;
      List<Device> devices;

      folder = folders[0];
      devices = folder.devices;
      expect(folder.id.value, equals('sample'));
      expect(devices, isEmpty);

      folder = folders[1];
      devices = folder.devices;
      expect(folder.id.value, equals('multiple'));
      expect(devices.length, equals(1));

      Device device = devices[0];
      expect(device.id.toString(), equals(idString));
      expect(device.flags.priority, equals(DeviceFlags.PRIORITY_HIGH));
      expect(device.flags.introducer, isTrue);
      expect(device.flags.readOnly, isFalse);
      expect(device.flags.trusted, isTrue);
      expect(device.maxLocalVersion.upper.value, equals(0xF0E1D2C3));
      expect(device.maxLocalVersion.lower.value, equals(0xB4A59687));

      List<Option> options = config.options;
      expect(options.length, equals(3));

      Option option;

      option = options[0];
      expect(option.key.value, equals('customFlag'));
      expect(option.value.value, equals('enabled'));

      option = options[1];
      expect(option.key.value, equals('secretOption'));
      expect(option.value.value, equals('disabled'));

      option = options[2];
      expect(option.key.value, equals('mode'));
      expect(option.value.value, equals('RANDOM'));
    });
  });
}

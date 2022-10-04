#!/usr/bin/env bash
PS4=$'+\e[34;1m# $LINENO #\e[0m '
P() { "$@" || (exit $(($? == 141 ? 0 : $?))); }
err_print() { echo $'\e[31;1m'"$? "$'\e[34;1m# '"$BASH_LINENO "$'#\e[0m '"$BASH_COMMAND";}
trap err_print ERR
shopt -s failglob
set -Eeuo pipefail
# --- Strict mode ---

# Nota Bene
# ---------
# This is a _self-contained_ shell script. Which is why proto IDL is embedded,
# thus may not be reflective of production use, and out of date.
# Primary intent is to provide a more practicable outlook. Helping get the gist.

# fd file
t=$(mktemp); exec 9<>$t; rm $t
cat >&9 <<'EOF'
syntax = "proto3";
package stxfw;
import "google/protobuf/descriptor.proto";

extend google.protobuf.FieldOptions {
	bool readonly = 50000;
}

enum PartNr {
	PARTNR_UNSPECIFIED = 0;
	PARTNR_STA_LR_868 = 1; // "sta-lr-868" Action Button, 868MHz
	PARTNR_STA_LR_915 = 2; // "sta-lr-915" Action Button, 915MHz
	PARTNR_STX_LR_868 = 3; // "stx-lr-868" Multi Sensor, 868MHz
	PARTNR_STX_LR_915 = 4; // "stx-lr-915" Multi Sensor, 915MHz
	PARTNR_STE_LR_868 = 5; // "ste-lr-868" Environment Sensor, 868MHz
	PARTNR_STE_LR_915 = 6; // "ste-lr-915" Environment Sensor, 915MHz
}

message Info {
	// Device Info
	// -----------

	// [ro] 1: uint8_t Device n-fuse Part Numbers
	// [ro] 2: uint8_t Firmware n-fuse release build number
	//     Likely will be seen in some form via `git tag`
	// [ro] 3: char[8] NFC STmicroelectronics Unique ID (iso15693)
	//     ST25DV System Register via I2C at 0xAE:0x0018+8 (DeviceAddr:TargetAddr+Bytes)
	// [ro] 4: uint8_t Battery Voltage
	//     Fixed-point number. Raw value range: [0..255]
	//     Volts = Value / 100 + 1
	PartNr device_part_number = 1 [(readonly) = true];
	uint32 device_fw_version = 2 [(readonly) = true];
	oneof has_device_nfc_uid {fixed64 device_nfc_uid = 3 [(readonly) = true];}
	oneof has_device_battery_voltage {uint32 device_battery_voltage = 4 [(readonly) = true];}

	// LoRa settings
	// -------------

	// [rw] 5:  char[8]   (TTN) Device EUI
	// [rw] 6:  char[8]   (TTN) Application EUI
	// [rw] 7:  char[16]  (TTN) App Key
	// [rw] 8:  uint32_t  (TTN) Device Address
	oneof has_lora_dev_eui {fixed64 lora_dev_eui = 5;}
	oneof has_lora_app_eui {fixed64 lora_app_eui = 6;}
	oneof has_lora_app_key {bytes lora_app_key = 7;}
	oneof has_lora_dev_addr {fixed32 lora_dev_addr = 8;}

	// [rw] 9:   char[16]  Network Session Key
	// [rw] 10:  char[16]  Network Session Key
	oneof has_lora_mac_net_session_key {bytes lora_mac_net_session_key = 9;}
	oneof has_lora_mac_app_session_key {bytes lora_mac_app_session_key = 10;}

	// WIP Below // I'm unfamiliar with these fields, may break tag numbers!

	// [ro] 11: bool Join success or failed.
	//     WIP Might be an enum.
	oneof has_lora_join_status {bool lora_join_status = 11 [(readonly) = true];}

	// WIP Don't know what these are.
	oneof has_lora_activation_method {bytes lora_activation_method = 12;}
	oneof has_lora_frequency_plan {bytes lora_frequency_plan = 13;}
	// [rw] WIP uint8_t
	oneof has_lora_port {uint32 lora_port = 14;}

	// Tinker
	// ------

	// [rw] 16: Varint boundaries as key of 1/2 bytes
	int32 stage1_last_key = 15;
	int32 stage2_first_key = 16;
	int32 stage2_second_key = 17;

	// [rw] 20: Float representation decode
	float float_decode = 31;

	// [rw] 128: Varint boundaries as value and key
	//     max_key = 2^29-1 encoded as 5 bytes
	//     max_value = 2^64-1 encoded as 10 bytes
	int32 largestkey_and_varint = 536870911;
}
EOF

printf '\n\e[34;1m%s\e[m\n' '# How large can our message get?'
printf `
	``# u8[8]   LoRa Device EUI:       {0x64, 0x65, 0x76, 0x69, 0x63, 0x65, 0x30, 0x32}`'\x29\x64\x65\x76\x69\x63\x65\x30\x32'`
	``# u8[8]   LoRa Application EUI:  {0x70, 0xB3, 0xD5, 0x7E, 0xF0, 0x00, 0x51, 0x2F}`'\x31\x70\xB3\xD5\x7E\xF0\x00\x51\x2F'`
	``# u8[16]  LoRa App Key:          {0x81, 0xFF, 0x80, 0xDE, 0x5E, 0x8F, 0x5C, 0x8E, 0x50, 0x84, 0x32, 0x24, 0xFF, 0x29, 0x2C, 0x42}`'\x3a\x10\x81\xFF\x80\xDE\x5E\x8F\x5C\x8E\x50\x84\x32\x24\xFF\x29\x2C\x42'`
	``# u32     LoRa Device Address:   0x26012A77`'\x45\x77\x2a\x01\x26'`
	``# enum    Device Part Number:    sta-lr-915`'\x08\x01'`
	``# u8      Device FW version:     0x00`''`
	``# u8[8]   Device NFC UID:        {0xA0, 0xB1, 0xC2, 0xD3, 0xE4, 0xF5, 0xA6, 0xB7}`'\x19\xA0\xB1\xC2\xD3\xE4\xF5\xA6\xB7'`
	``# u8      Device Battery Volts:  2.28V aka 0x80`'\x20\x80\x01'`
	``# bool    LoRa Join Status:      false`'\x58\x00'`
	``# u8[16]  LoRa MAC App SKey:     {0x77, 0x9B, 0x7F, 0xFC, 0xE1, 0x0C, 0xD2, 0xA4, 0x9D, 0x05, 0xB5, 0xF5, 0x8E, 0xEA, 0xA1, 0x7B}`'\x52\x10\x77\x9B\x7F\xFC\xE1\x0C\xD2\xA4\x9D\x05\xB5\xF5\x8E\xEA\xA1\x7B'`
	``# u8[16]  LoRa MAC Net SKey:     {0x9C, 0x1E, 0xDA, 0xE8, 0x57, 0x2C, 0xA0, 0x7F, 0x5F, 0x7E, 0x7B, 0x11, 0x3C, 0xD4, 0xF1, 0x50}`'\x4a\x10\x9C\x1E\xDA\xE8\x57\x2C\xA0\x7F\x5F\x7E\x7B\x11\x3C\xD4\xF1\x50'`
	` | tee >(od -v -Ad -tx1 >/dev/stderr) | protoc --decode stxfw.Info --proto_path /dev/fd /dev/fd/9

printf '\n\e[34;1m%s\e[m\n' '# Key integer continuation into 2nd byte?'
printf 'stage1_last_key: 0x7f\nstage2_first_key: 0x7e\nstage2_second_key: 0x7d\n' | protoc --encode stxfw.Info --proto_path /dev/fd /dev/fd/9 | od -v -Ad -tx1

printf '\n\e[34;1m%s\e[m\n' '# Largest values? Behaviour on unused bits being set?'
printf 'largestkey_and_varint: -1' | protoc --encode stxfw.Info --proto_path /dev/fd /dev/fd/9 | od -v -Ad -tx1
printf '\xf8\xff\xff\xff\x0f\xff\xff\xff\xff\xff\xff\xff\xff\xff\x01' | protoc --decode stxfw.Info --proto_path /dev/fd /dev/fd/9
printf '\xf8\xff\xff\xff\x7f\xff\xff\xff\xff\xff\xff\xff\xff\xff\x7f' | protoc --decode stxfw.Info --proto_path /dev/fd /dev/fd/9

printf '\n\e[34;1m%s\e[m\n' '# Endianess?'
printf 'lora_dev_eui: 1' | protoc --encode stxfw.Info --proto_path /dev/fd /dev/fd/9 | od -v -Ad -tx1
printf '\x29\x01\x00\x00\x00\x00\x00\x00\x00' | protoc --decode stxfw.Info --proto_path /dev/fd /dev/fd/9
printf 'lora_app_key: "\x30\x31\x32\x33\x34\x35"' | protoc --encode stxfw.Info --proto_path /dev/fd /dev/fd/9 | od -v -Ad -tx1
printf '\x3a\x06\x30\x31\x32\x33\x34\x35' | protoc --decode stxfw.Info --proto_path /dev/fd /dev/fd/9

printf '\n\e[34;1m%s\e[m\n' '# Are (without oneof) defaults silenced?'
printf 'device_fw_version: 00' | protoc --encode stxfw.Info --proto_path /dev/fd /dev/fd/9 | od -v -Ad -tx1
printf '\x10\x00' | protoc --decode stxfw.Info --proto_path /dev/fd /dev/fd/9

printf '\n\e[34;1m%s\e[m\n' '# Are floats just little endian C float? (float)INFINITY is (char[4]){0x00, 0x00, 0x80, 0x7f}'
printf 'float_decode: inf' | protoc --encode stxfw.Info --proto_path /dev/fd /dev/fd/9 | od -v -Ad -tx1
printf '\xfd\x01\x00\x00\x80\x7f' | protoc --decode stxfw.Info --proto_path /dev/fd /dev/fd/9

:||: <<'EOF'
Helpers
-------
user$ <<<'0x64, 0x65, 0x76, 0x69, 0x63, 0x65, 0x30, 0x32' grep -o 'x..' | awk '{printf("\\%s", $0)}END{print ""}'
\x64\x65\x76\x69\x63\x65\x30\x32

user$ <<<'\x64\x65\x76\x69\x63\x65\x30\x32' grep -o 'x..' | awk '{printf((NR==1?"{": ", ")"0%s", $0)}END{print "}"}'
{0x64, 0x65, 0x76, 0x69, 0x63, 0x65, 0x30, 0x32}

user$ <<<'29 01 00 00 00 00 00 00 00' grep -o '[^ ]\+' | awk '{printf("\\x%s", $0)}END{print ""}'
EOF

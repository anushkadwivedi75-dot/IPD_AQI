import asyncio
import random
import struct
import sys
from bless import BlessServer, BlessGATTCharacteristic, GATTCharacteristicProperties, GATTAttributePermissions

SERVICE_UUID = "12345678-1234-5678-1234-56789abcdef0"
AQI_CHAR_UUID = "12345678-1234-5678-1234-56789abcdef1"
HUMIDITY_CHAR_UUID = "12345678-1234-5678-1234-56789abcdef2"
BATTERY_CHAR_UUID = "12345678-1234-5678-1234-56789abcdef3"

async def check_windows_peripheral_support() -> bool:
    if sys.platform == "win32":
        try:
            from winrt.windows.devices.bluetooth import BluetoothAdapter
            adapter = await BluetoothAdapter.get_default_async()
            if adapter is None or not adapter.is_peripheral_role_supported:
                return False
        except Exception:
            pass
    return True

async def run_mock_simulation():
    print("[MOCK SIMULATOR] Running in mock data mode (Bluetooth Peripheral Advertising is not supported by your PC's adapter)...")
    try:
        while True:
            aqi = random.randint(60, 180)
            humidity = round(random.uniform(45, 70), 1)
            battery = random.randint(60, 100)
            print(f"[MOCK DATA] AQI={aqi} humidity={humidity}% battery={battery}%")
            await asyncio.sleep(4)
    except KeyboardInterrupt:
        print("\nMock simulator stopped.")

async def run():
    has_peripheral_support = await check_windows_peripheral_support()
    if not has_peripheral_support:
        print("ERROR: Your Bluetooth adapter does not support BLE Peripheral / GATT Server Advertising mode (adapter.is_peripheral_role_supported == False).")
        print("Falling back to Mock Data Mode...\n")
        await run_mock_simulation()
        return

    server = BlessServer(name="AirSentinel Pod SIM")
    await server.add_new_service(SERVICE_UUID)

    props = GATTCharacteristicProperties.read | GATTCharacteristicProperties.notify
    perms = GATTAttributePermissions.readable

    await server.add_new_characteristic(SERVICE_UUID, AQI_CHAR_UUID, props, None, perms)
    await server.add_new_characteristic(SERVICE_UUID, HUMIDITY_CHAR_UUID, props, None, perms)
    await server.add_new_characteristic(SERVICE_UUID, BATTERY_CHAR_UUID, props, None, perms)

    try:
        await server.start()
        print("Advertising as AirSentinel Pod SIM...")
    except OSError as e:
        print(f"\nFailed to start BLE GATT Server: {e}")
        print("Your Bluetooth hardware/driver does not support Peripheral advertising mode.")
        print("Switching to Mock Data Mode...\n")
        await run_mock_simulation()
        return

    try:
        while True:
            aqi = random.randint(60, 180)
            humidity = round(random.uniform(45, 70), 1)
            battery = random.randint(60, 100)

            server.get_characteristic(AQI_CHAR_UUID).value = struct.pack("<H", aqi)
            server.get_characteristic(HUMIDITY_CHAR_UUID).value = struct.pack("<f", humidity)
            server.get_characteristic(BATTERY_CHAR_UUID).value = struct.pack("<B", battery)

            server.update_value(SERVICE_UUID, AQI_CHAR_UUID)
            server.update_value(SERVICE_UUID, HUMIDITY_CHAR_UUID)
            server.update_value(SERVICE_UUID, BATTERY_CHAR_UUID)

            print(f"AQI={aqi} humidity={humidity} battery={battery}")
            await asyncio.sleep(4)
    except KeyboardInterrupt:
        await server.stop()

if __name__ == "__main__":
    asyncio.run(run())
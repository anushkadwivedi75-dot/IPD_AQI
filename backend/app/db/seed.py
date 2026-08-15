import asyncio
import random
import uuid
from datetime import datetime, timedelta, timezone
from geoalchemy2.elements import WKTElement

from sqlalchemy import text

from app.db.session import AsyncSessionLocal
from app.models.user import User
from app.models.device import Device
from app.models.site import Site
from app.models.reading import Reading


async def seed_data():
    async with AsyncSessionLocal() as db:
        print("[SEED] Starting database seeding...")

        # Clear existing data for clean idempotent seeding
        await db.execute(text("TRUNCATE TABLE readings, sites, devices, users RESTART IDENTITY CASCADE;"))
        await db.commit()


        # 1. Create 3 fake users
        users = [
            User(id=uuid.uuid4(), phone_or_email="admin@airsentine1.org", role="admin"),
            User(id=uuid.uuid4(), phone_or_email="analyst@airsentine1.org", role="analyst"),
            User(id=uuid.uuid4(), phone_or_email="citizen@airsentine1.org", role="citizen"),
        ]
        db.add_all(users)
        await db.flush()

        # 2. Create 5 fake devices
        devices = [
            Device(id=uuid.uuid4(), owner_user_id=users[0].id, device_uid="DEV-BKC-001", type="official_station"),
            Device(id=uuid.uuid4(), owner_user_id=users[1].id, device_uid="DEV-BKC-002", type="community_sensor"),
            Device(id=uuid.uuid4(), owner_user_id=users[0].id, device_uid="DEV-COLABA-001", type="official_station"),
            Device(id=uuid.uuid4(), owner_user_id=users[2].id, device_uid="DEV-COLABA-002", type="community_sensor"),
            Device(id=uuid.uuid4(), owner_user_id=users[2].id, device_uid="DEV-MOBILE-001", type="mobile_sensor"),
        ]
        db.add_all(devices)
        await db.flush()

        # 3. Create 2 fake sites in Mumbai
        sites = [
            Site(
                id=uuid.uuid4(),
                name="Bandra Kurla Complex (BKC)",
                location=WKTElement("POINT(72.8686 19.0657)", srid=4326),
                official_device_id=devices[0].id,
                status="active",
            ),
            Site(
                id=uuid.uuid4(),
                name="Colaba Marine Drive",
                location=WKTElement("POINT(72.8258 18.9220)", srid=4326),
                official_device_id=devices[2].id,
                status="active",
            ),
        ]
        db.add_all(sites)
        await db.flush()

        # 4. Create 200 fake readings scattered around those sites over the last 48h
        now = datetime.now(timezone.utc)
        readings = []

        # 100 readings around BKC (19.0657, 72.8686)
        for _ in range(100):
            lat_offset = random.uniform(-0.003, 0.003)
            lng_offset = random.uniform(-0.003, 0.003)
            lat = 19.0657 + lat_offset
            lng = 72.8686 + lng_offset

            minutes_ago = random.randint(0, 48 * 60)
            rec_at = now - timedelta(minutes=minutes_ago)

            aqi = random.randint(60, 240)
            pm25 = round(aqi * random.uniform(0.4, 0.6), 2)
            humidity = round(random.uniform(50.0, 85.0), 2)
            device = random.choice([devices[0], devices[1], devices[4]])

            reading = Reading(
                device_id=device.id,
                aqi=aqi,
                pm25=pm25,
                humidity=humidity,
                location=WKTElement(f"POINT({lng:.6f} {lat:.6f})", srid=4326),
                recorded_at=rec_at,
            )
            readings.append(reading)

        # 100 readings around Colaba (18.9220, 72.8258)
        for _ in range(100):
            lat_offset = random.uniform(-0.003, 0.003)
            lng_offset = random.uniform(-0.003, 0.003)
            lat = 18.9220 + lat_offset
            lng = 72.8258 + lng_offset

            minutes_ago = random.randint(0, 48 * 60)
            rec_at = now - timedelta(minutes=minutes_ago)

            aqi = random.randint(45, 190)
            pm25 = round(aqi * random.uniform(0.35, 0.55), 2)
            humidity = round(random.uniform(55.0, 90.0), 2)
            device = random.choice([devices[2], devices[3], devices[4]])

            reading = Reading(
                device_id=device.id,
                aqi=aqi,
                pm25=pm25,
                humidity=humidity,
                location=WKTElement(f"POINT({lng:.6f} {lat:.6f})", srid=4326),
                recorded_at=rec_at,
            )
            readings.append(reading)

        db.add_all(readings)
        await db.commit()

        print(f"[SEED] Seeding complete! Created {len(users)} users, {len(devices)} devices, {len(sites)} sites, and {len(readings)} readings.")


if __name__ == "__main__":
    asyncio.run(seed_data())

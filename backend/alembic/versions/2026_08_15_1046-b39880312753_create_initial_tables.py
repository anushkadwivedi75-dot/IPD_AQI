"""create_initial_tables

Revision ID: b39880312753
Revises: None
Create Date: 2026-08-15 10:46:01.925820

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql
import geoalchemy2


# revision identifiers, used by Alembic.
revision: str = 'b39880312753'
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Enable PostGIS extension
    op.execute("CREATE EXTENSION IF NOT EXISTS postgis;")

    # 1. users
    op.create_table(
        'users',
        sa.Column(
            'id',
            postgresql.UUID(as_uuid=True),
            server_default=sa.text('gen_random_uuid()'),
            nullable=False,
        ),
        sa.Column('phone_or_email', sa.String(), nullable=True),
        sa.Column('role', sa.String(), nullable=True),
        sa.PrimaryKeyConstraint('id'),
    )

    # 2. devices
    op.create_table(
        'devices',
        sa.Column(
            'id',
            postgresql.UUID(as_uuid=True),
            server_default=sa.text('gen_random_uuid()'),
            nullable=False,
        ),
        sa.Column('owner_user_id', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('device_uid', sa.String(), nullable=True),
        sa.Column('type', sa.String(), nullable=True),
        sa.ForeignKeyConstraint(['owner_user_id'], ['users.id'], ondelete='SET NULL'),
        sa.PrimaryKeyConstraint('id'),
    )

    # 3. readings
    op.create_table(
        'readings',
        sa.Column('id', sa.BigInteger(), autoincrement=True, nullable=False),
        sa.Column('device_id', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('aqi', sa.SmallInteger(), nullable=True),
        sa.Column('pm25', sa.Float(), nullable=True),
        sa.Column('humidity', sa.Float(), nullable=True),
        sa.Column(
            'location',
            geoalchemy2.types.Geography(
                geometry_type='POINT',
                srid=4326,
                spatial_index=True,
                from_text='ST_GeogFromText',
                name='geography',
            ),
            nullable=True,
        ),
        sa.Column('recorded_at', sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(['device_id'], ['devices.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )

    # 4. sites
    op.create_table(
        'sites',
        sa.Column(
            'id',
            postgresql.UUID(as_uuid=True),
            server_default=sa.text('gen_random_uuid()'),
            nullable=False,
        ),
        sa.Column('name', sa.String(), nullable=True),
        sa.Column(
            'location',
            geoalchemy2.types.Geography(
                geometry_type='POINT',
                srid=4326,
                spatial_index=True,
                from_text='ST_GeogFromText',
                name='geography',
            ),
            nullable=True,
        ),
        sa.Column('official_device_id', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('status', sa.String(), nullable=True),
        sa.ForeignKeyConstraint(['official_device_id'], ['devices.id'], ondelete='SET NULL'),
        sa.PrimaryKeyConstraint('id'),
    )

    # 5. community_reports
    op.create_table(
        'community_reports',
        sa.Column(
            'id',
            postgresql.UUID(as_uuid=True),
            server_default=sa.text('gen_random_uuid()'),
            nullable=False,
        ),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('site_id', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column(
            'location',
            geoalchemy2.types.Geography(
                geometry_type='POINT',
                srid=4326,
                spatial_index=True,
                from_text='ST_GeogFromText',
                name='geography',
            ),
            nullable=True,
        ),
        sa.Column('note', sa.Text(), nullable=True),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['site_id'], ['sites.id'], ondelete='SET NULL'),
        sa.PrimaryKeyConstraint('id'),
    )

    # 6. alerts
    op.create_table(
        'alerts',
        sa.Column(
            'id',
            postgresql.UUID(as_uuid=True),
            server_default=sa.text('gen_random_uuid()'),
            nullable=False,
        ),
        sa.Column('site_id', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('type', sa.String(), nullable=True),
        sa.Column('severity', sa.SmallInteger(), nullable=True),
        sa.Column('evidence', postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.ForeignKeyConstraint(['site_id'], ['sites.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )


def downgrade() -> None:
    op.drop_table('alerts')
    op.drop_table('community_reports')
    op.drop_table('sites')
    op.drop_table('readings')
    op.drop_table('devices')
    op.drop_table('users')
    op.execute("DROP EXTENSION IF EXISTS postgis;")

import pytest
from app.services.alert_service import process_vital_reading

# Mock data
class MockVital:
    def __init__(self, vital_type, value):
        self.vital_type = vital_type
        self.value = value

def test_process_vital_reading_blood_pressure_high():
    vital = MockVital("blood_pressure_systolic", 150)
    alerts = process_vital_reading(vital)
    # Expected: 1 alert, Critical
    assert len(alerts) == 1
    assert alerts[0]["severity"] == "critical"
    assert "blood_pressure_systolic" in alerts[0]["message"]

def test_process_vital_reading_blood_pressure_normal():
    vital = MockVital("blood_pressure_systolic", 120)
    alerts = process_vital_reading(vital)
    # Expected: 0 alerts
    assert len(alerts) == 0

def test_process_vital_reading_heart_rate_low():
    vital = MockVital("heart_rate", 45)
    alerts = process_vital_reading(vital)
    assert len(alerts) == 1
    assert alerts[0]["severity"] == "critical"

def test_process_vital_reading_glucose_warning():
    vital = MockVital("blood_sugar_fasting", 110)
    alerts = process_vital_reading(vital)
    assert len(alerts) == 1
    assert alerts[0]["severity"] == "warning"

def test_process_vital_reading_oxygen_low():
    vital = MockVital("oxygen_saturation", 90)
    alerts = process_vital_reading(vital)
    assert len(alerts) == 1
    assert alerts[0]["severity"] == "critical"

def test_process_vital_reading_temperature_normal():
    vital = MockVital("temperature", 98.6)
    alerts = process_vital_reading(vital)
    assert len(alerts) == 0

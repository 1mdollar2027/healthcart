"""
Alert Service – Vitals rule engine for IoT monitoring.
Checks vital readings against thresholds and generates alerts.
"""

# Threshold rules: (vital_type, condition, threshold, severity, title, body)
ALERT_RULES = [
    # Blood Pressure
    {
        "vital_type": "blood_pressure_systolic",
        "rules": [
            {"op": ">=", "val": 180, "severity": "critical", "title": "🚨 Critical: Very High BP", "body": "Systolic BP is {value} mmHg (≥180). Seek immediate medical attention!"},
            {"op": ">=", "val": 160, "severity": "high", "title": "⚠️ High Blood Pressure", "body": "Systolic BP is {value} mmHg (≥160). Please consult your doctor soon."},
            {"op": ">=", "val": 140, "severity": "warning", "title": "📊 Elevated BP", "body": "Systolic BP is {value} mmHg (≥140). Monitor closely and follow your treatment plan."},
            {"op": "<=", "val": 90, "severity": "warning", "title": "📉 Low Blood Pressure", "body": "Systolic BP is {value} mmHg (≤90). Stay hydrated and rest."},
        ],
    },
    {
        "vital_type": "blood_pressure_diastolic",
        "rules": [
            {"op": ">=", "val": 120, "severity": "critical", "title": "🚨 Critical: Very High Diastolic BP", "body": "Diastolic BP is {value} mmHg (≥120). Seek immediate attention!"},
            {"op": ">=", "val": 100, "severity": "high", "title": "⚠️ High Diastolic BP", "body": "Diastolic BP is {value} mmHg (≥100). Consult your doctor."},
            {"op": ">=", "val": 90, "severity": "warning", "title": "📊 Elevated Diastolic BP", "body": "Diastolic BP is {value} mmHg (≥90). Monitor closely."},
        ],
    },
    # Blood Glucose
    {
        "vital_type": "blood_glucose",
        "rules": [
            {"op": ">=", "val": 300, "severity": "critical", "title": "🚨 Critical: Very High Glucose", "body": "Blood glucose is {value} mg/dL (≥300). Seek immediate medical help!"},
            {"op": ">=", "val": 200, "severity": "high", "title": "⚠️ High Blood Sugar", "body": "Blood glucose is {value} mg/dL (≥200). Take action per your diabetes plan."},
            {"op": ">=", "val": 140, "severity": "warning", "title": "📊 Elevated Blood Sugar", "body": "Blood glucose is {value} mg/dL (≥140). Monitor and manage diet."},
            {"op": "<=", "val": 70, "severity": "high", "title": "⚠️ Low Blood Sugar", "body": "Blood glucose is {value} mg/dL (≤70). Eat something sugary immediately."},
            {"op": "<=", "val": 54, "severity": "critical", "title": "🚨 Critical: Very Low Glucose", "body": "Blood glucose is {value} mg/dL (≤54). Medical emergency – seek help immediately!"},
        ],
    },
    # Heart Rate
    {
        "vital_type": "heart_rate",
        "rules": [
            {"op": ">=", "val": 120, "severity": "high", "title": "⚠️ High Heart Rate", "body": "Heart rate is {value} bpm (≥120). Rest and monitor. Consult if persistent."},
            {"op": ">=", "val": 100, "severity": "warning", "title": "📊 Elevated Heart Rate", "body": "Heart rate is {value} bpm (≥100). Take deep breaths and rest."},
            {"op": "<=", "val": 50, "severity": "warning", "title": "📉 Low Heart Rate", "body": "Heart rate is {value} bpm (≤50). Monitor closely."},
            {"op": "<=", "val": 40, "severity": "high", "title": "⚠️ Very Low Heart Rate", "body": "Heart rate is {value} bpm (≤40). Seek medical attention."},
        ],
    },
    # SpO2
    {
        "vital_type": "spo2",
        "rules": [
            {"op": "<=", "val": 90, "severity": "critical", "title": "🚨 Critical: Low Oxygen", "body": "SpO2 is {value}% (≤90). Seek immediate medical help!"},
            {"op": "<=", "val": 94, "severity": "high", "title": "⚠️ Low Oxygen Level", "body": "SpO2 is {value}% (≤94). Monitor closely and contact your doctor."},
        ],
    },
    # Temperature
    {
        "vital_type": "temperature",
        "rules": [
            {"op": ">=", "val": 103, "severity": "critical", "title": "🚨 High Fever", "body": "Temperature is {value}°F (≥103). Seek medical attention immediately!"},
            {"op": ">=", "val": 100.4, "severity": "high", "title": "⚠️ Fever Detected", "body": "Temperature is {value}°F (≥100.4). Take paracetamol and rest. Monitor closely."},
            {"op": ">=", "val": 99.5, "severity": "warning", "title": "📊 Low-Grade Fever", "body": "Temperature is {value}°F (≥99.5). Rest and stay hydrated."},
        ],
    },
]


def check_vital_alerts(vital_type: str, value: float) -> list[dict]:
    """
    Check a vital reading against threshold rules.

    Returns:
        List of triggered alerts with title, body, severity
    """
    alerts = []

    for rule_group in ALERT_RULES:
        if rule_group["vital_type"] != vital_type:
            continue

        for rule in rule_group["rules"]:
            triggered = False
            if rule["op"] == ">=" and value >= rule["val"]:
                triggered = True
            elif rule["op"] == "<=" and value <= rule["val"]:
                triggered = True

            if triggered:
                alerts.append({
                    "title": rule["title"],
                    "body": rule["body"].format(value=value),
                    "severity": rule["severity"],
                    "threshold": rule["val"],
                })
                break  # Only trigger highest severity per rule group

    return alerts

"""
PDF Service – Generate prescription PDFs using WeasyPrint + Jinja2.
"""
from datetime import date, datetime
from jinja2 import Template
import io

PRESCRIPTION_HTML = """
<!DOCTYPE html>
<html>
<head>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { font-family: 'Segoe UI', Arial, sans-serif; padding: 30px; color: #1a1a2e; }
  .header { display: flex; justify-content: space-between; align-items: center; border-bottom: 3px solid #0f3460; padding-bottom: 15px; margin-bottom: 20px; }
  .logo { font-size: 28px; font-weight: 800; color: #0f3460; }
  .logo span { color: #e94560; }
  .header-right { text-align: right; font-size: 12px; color: #555; }
  .doctor-info { background: linear-gradient(135deg, #0f3460, #16213e); color: white; padding: 15px 20px; border-radius: 8px; margin-bottom: 20px; }
  .doctor-info h2 { margin-bottom: 5px; font-size: 18px; }
  .doctor-info p { font-size: 13px; opacity: 0.9; }
  .patient-info { display: flex; gap: 30px; margin-bottom: 20px; padding: 12px 15px; background: #f0f4ff; border-radius: 6px; }
  .patient-info div { font-size: 13px; }
  .patient-info strong { color: #0f3460; }
  .rx-symbol { font-size: 24px; color: #0f3460; font-weight: bold; margin: 15px 0 10px; }
  .section-title { font-size: 15px; font-weight: 700; color: #0f3460; margin: 15px 0 8px; text-transform: uppercase; letter-spacing: 1px; }
  table { width: 100%; border-collapse: collapse; margin-bottom: 15px; }
  th { background: #0f3460; color: white; padding: 10px 12px; text-align: left; font-size: 12px; text-transform: uppercase; }
  td { padding: 10px 12px; border-bottom: 1px solid #e0e0e0; font-size: 13px; }
  tr:nth-child(even) { background: #f8f9ff; }
  .diagnosis { background: #fff3cd; padding: 12px 15px; border-radius: 6px; border-left: 4px solid #ffc107; margin-bottom: 15px; }
  .advice { background: #d4edda; padding: 12px 15px; border-radius: 6px; border-left: 4px solid #28a745; margin-bottom: 15px; }
  .follow-up { background: #cce5ff; padding: 12px 15px; border-radius: 6px; border-left: 4px solid #007bff; margin-bottom: 20px; }
  .footer { border-top: 2px solid #e0e0e0; padding-top: 15px; margin-top: 20px; display: flex; justify-content: space-between; }
  .signature { text-align: right; }
  .signature .line { width: 200px; border-top: 1px solid #333; margin: 30px 0 5px auto; }
  .stamp { font-size: 10px; color: #888; text-align: center; margin-top: 20px; }
  .watermark { position: fixed; top: 50%; left: 50%; transform: translate(-50%, -50%) rotate(-45deg); font-size: 80px; color: rgba(15,52,96,0.03); font-weight: 900; z-index: -1; }
</style>
</head>
<body>
<div class="watermark">HEALTHCART</div>

<div class="header">
  <div class="logo">Health<span>Cart</span></div>
  <div class="header-right">
    <strong>Digital Prescription</strong><br>
    Rx ID: {{ prescription_id[:8] }}<br>
    Date: {{ date }}
  </div>
</div>

<div class="doctor-info">
  <h2>Dr. {{ doctor_name }}</h2>
  <p>HealthCart Verified Practitioner</p>
</div>

<div class="patient-info">
  <div><strong>Patient:</strong> {{ patient_name }}</div>
  <div><strong>Date:</strong> {{ date }}</div>
  <div><strong>Rx ID:</strong> {{ prescription_id[:8] }}</div>
</div>

{% if diagnosis %}
<div class="diagnosis">
  <div class="section-title" style="margin-top:0">Diagnosis</div>
  <p>{{ diagnosis }}</p>
</div>
{% endif %}

<div class="rx-symbol">℞</div>
<div class="section-title">Prescribed Medicines</div>
<table>
  <tr>
    <th>#</th>
    <th>Medicine</th>
    <th>Dosage</th>
    <th>Frequency</th>
    <th>Duration</th>
    <th>Instructions</th>
  </tr>
  {% for item in items %}
  <tr>
    <td>{{ loop.index }}</td>
    <td><strong>{{ item.medicine_name }}</strong></td>
    <td>{{ item.dosage }}</td>
    <td>{{ item.frequency }}</td>
    <td>{{ item.duration }}</td>
    <td>{{ item.instructions or '-' }}</td>
  </tr>
  {% endfor %}
</table>

{% if advice %}
<div class="advice">
  <div class="section-title" style="margin-top:0">Advice</div>
  <p>{{ advice }}</p>
</div>
{% endif %}

{% if follow_up_date %}
<div class="follow-up">
  <div class="section-title" style="margin-top:0">Follow-up</div>
  <p>Please schedule a follow-up on <strong>{{ follow_up_date }}</strong></p>
</div>
{% endif %}

<div class="footer">
  <div>
    <p style="font-size: 11px; color: #888;">
      This is a digitally generated prescription via HealthCart.<br>
      Compliant with DPDP Act 2023. Not a substitute for in-person consultation where required.
    </p>
  </div>
  <div class="signature">
    <div class="line"></div>
    <strong>Dr. {{ doctor_name }}</strong><br>
    <span style="font-size: 11px; color: #666;">Digital Signature</span>
  </div>
</div>

<div class="stamp">
  Generated at {{ timestamp }} IST | HealthCart Telemedicine Platform | Jaipur, Rajasthan
</div>
</body>
</html>
"""


def generate_prescription_pdf(
    prescription_id: str,
    doctor_name: str,
    patient_name: str,
    diagnosis: str,
    advice: str,
    items: list[dict],
    follow_up_date: date | None = None,
) -> bytes:
    """
    Generate a premium prescription PDF.

    Returns:
        PDF as bytes
    """
    template = Template(PRESCRIPTION_HTML)
    now = datetime.now()

    html_content = template.render(
        prescription_id=prescription_id,
        doctor_name=doctor_name,
        patient_name=patient_name,
        diagnosis=diagnosis,
        advice=advice,
        items=items,
        follow_up_date=follow_up_date.isoformat() if follow_up_date else None,
        date=now.strftime("%d %b %Y"),
        timestamp=now.strftime("%d %b %Y, %I:%M %p"),
    )

    try:
        from weasyprint import HTML
        pdf_bytes = HTML(string=html_content).write_pdf()
        return pdf_bytes
    except ImportError:
        # Fallback: return HTML as bytes if WeasyPrint not installed
        return html_content.encode("utf-8")

export default function PrivacyPolicy() {
    return (
        <div className="min-h-screen bg-gray-50 flex flex-col py-12 px-4 sm:px-6 lg:px-8 font-sans">
            <div className="max-w-4xl mx-auto bg-white p-8 md:p-12 shadow-sm rounded-2xl">
                <h1 className="text-3xl font-bold text-gray-900 mb-6">Privacy Policy</h1>
                <p className="text-sm text-gray-500 mb-8">Effective Date: March 2026</p>

                <section className="mb-8">
                    <h2 className="text-xl font-semibold text-gray-800 mb-4">1. Introduction</h2>
                    <p className="text-gray-600 leading-relaxed">
                        Welcome to HealthCart. We are committed to protecting your privacy and ensuring you have a secure experience on our telemedicine platform. This Privacy Policy outlines how we collect, use, and safeguard your personal and health data in strict compliance with the Digital Personal Data Protection (DPDP) Act 2023 of India.
                    </p>
                </section>

                <section className="mb-8">
                    <h2 className="text-xl font-semibold text-gray-800 mb-4">2. Data We Collect</h2>
                    <ul className="list-disc list-inside text-gray-600 space-y-2">
                        <li><strong>Identity & Contact:</strong> Name, phone number, email (for authentication and OTP verification).</li>
                        <li><strong>Health Data:</strong> Vitals (e.g., blood pressure, glucose, cardiac rhythms pushed via IoT devices), prescriptions, medical history, and consultation notes.</li>
                        <li><strong>Transaction Data:</strong> Bookings, appointment history, and payment statuses (actual payment processing is handled securely by Razorpay).</li>
                        <li><strong>Technical Data:</strong> Device information (camera and microphone access explicitly requested for Agora video consultations).</li>
                    </ul>
                </section>

                <section className="mb-8">
                    <h2 className="text-xl font-semibold text-gray-800 mb-4">3. Purpose of Collection</h2>
                    <p className="text-gray-600 leading-relaxed">
                        We collect the absolute minimum data required to facilitate:
                        <br />• Telemedicine video consultations with licensed doctors.
                        <br />• Generation and secure delivery of digital prescriptions.
                        <br />• Home lab sample collections and medicine delivery routing.
                        <br />• Automated push notification alerts for critical vital readings (via FCM).
                    </p>
                </section>

                <section className="mb-8">
                    <h2 className="text-xl font-semibold text-gray-800 mb-4">4. Data Sharing & Disclosure</h2>
                    <p className="text-gray-600 leading-relaxed">
                        Your data is never sold. It is only shared securely with:
                        <br />• <strong>Medical Professionals:</strong> Your chosen doctors to facilitate treatment.
                        <br />• <strong>Partner Facilities:</strong> Labs and pharmacies, strictly upon your verified booking confirmation.
                        <br />• <strong>Infrastructural Partners:</strong> Razorpay (UPI payments), Agora (Video streaming infrastructure, no recording stored), and Supabase (Encrypted database storage).
                    </p>
                </section>

                <section className="mb-8">
                    <h2 className="text-xl font-semibold text-gray-800 mb-4">5. Your DPDP Act 2023 Rights</h2>
                    <p className="text-gray-600 leading-relaxed">
                        Under Indian law, you possess explicit rights regarding your digital personal data:
                        <br />• <strong>Right to Access:</strong> Request a summary of the personal data processed by us.
                        <br />• <strong>Right to Correction & Erasure:</strong> Modify inaccurate data or request complete deletion of your profile.
                        <br />• <strong>Right to Withdraw Consent:</strong> You may withdraw your consent for data processing at any time through the app settings.
                        <br />• <strong>Verifiable Consent:</strong> If services are provided to a minor, verifiable consent is obtained from the legal guardian. No blanket or implied consent is utilized.
                    </p>
                </section>

                <section className="mb-8">
                    <h2 className="text-xl font-semibold text-gray-800 mb-4">6. Security Measures</h2>
                    <p className="text-gray-600 leading-relaxed">
                        HealthCart utilizes state-of-the-art security, including TLS/HTTPS encryption in transit, strict database Row-Level Security (RLS) policies ensuring only authorized patients and assigned doctors can view specific health records, and comprehensive enterprise-grade audit logging.
                    </p>
                </section>

                <section className="mb-8">
                    <h2 className="text-xl font-semibold text-gray-800 mb-4">7. Contact Us</h2>
                    <p className="text-gray-600 leading-relaxed">
                        For questions, grievances, or to exercise your rights, please contact our Data Protection Officer at:
                        <br /><strong>Email:</strong> support@healthcart.in
                    </p>
                </section>

            </div>
        </div>
    );
}

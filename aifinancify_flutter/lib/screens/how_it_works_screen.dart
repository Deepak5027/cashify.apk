import 'package:flutter/material.dart';

class HowItWorksScreen extends StatelessWidget {
  const HowItWorksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        elevation: 0,
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text("How AiFinancify Works", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Hero Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Intelligent Financial Automation",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 6),
                Text(
                  "Discover how our AI tools automate transaction logging, budgeting, receipt scanning, and predictive forecasting.",
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _buildStepCard(
            "1",
            "OCR Receipt Scanning",
            "Take a photo or upload a paper receipt. Our on-device Google ML Kit OCR detects merchant names, transaction dates, and itemized totals automatically.",
            Icons.camera_alt_outlined,
            Colors.indigoAccent,
          ),
          _buildStepCard(
            "2",
            "Natural Language Voice Entry",
            "Speak your transactions naturally (e.g. 'Spent ₹450 on groceries at Walmart'). The voice parser extracts the amount, vendor, and category instantly.",
            Icons.mic_outlined,
            Colors.purpleAccent,
          ),
          _buildStepCard(
            "3",
            "Indian UPI SMS Parser",
            "Paste your payment SMS notifications from SBI, HDFC, ICICI, Paytm, PhonePe, or GPay to auto-extract transaction reference numbers and amounts.",
            Icons.message_outlined,
            Colors.greenAccent,
          ),
          _buildStepCard(
            "4",
            "Bank Statement CSV Importer",
            "Import bulk transaction statements with automatic header detection for Chase, Bank of America, and custom spreadsheets with interactive preview.",
            Icons.file_upload_outlined,
            Colors.amberAccent,
          ),
          _buildStepCard(
            "5",
            "Predictive ML & Smart Insights",
            "Our machine learning model analyzes your historical spending velocity to predict end-of-month cash burn and warn you before budget overruns occur.",
            Icons.online_prediction,
            Colors.blueAccent,
          ),
          _buildStepCard(
            "6",
            "Automated Fraud & Anomaly Alerts",
            "Every logged transaction is scored from 0-100% against your standard habits to immediately flag unusually high charges or suspicious categories.",
            Icons.shield_outlined,
            Colors.redAccent,
          ),
          _buildStepCard(
            "7",
            "Conversational Financial Chatbot",
            "Ask questions like 'How much have I spent on food this month?' and receive instant, personalized breakdowns directly from your actual database records.",
            Icons.chat_bubble_outline,
            Colors.tealAccent,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStepCard(String number, String title, String description, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white60, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

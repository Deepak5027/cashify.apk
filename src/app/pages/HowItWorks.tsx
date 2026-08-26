import { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '../components/ui/card';
import { TrendingUp, ShieldAlert, BarChart3, Clock, Zap, Search, ArrowLeft, Info, Download, FileText } from 'lucide-react';
import { Button } from '../components/ui/button';
import { Link } from 'react-router';
import { Badge } from '../components/ui/badge';
import { toast } from 'sonner';
import { transactionsAPI } from '../../services/api';
import { exportFinancialReportPDF } from '../../utils/exportUtils';

/**
 * "How Our AI Works" — plain-English transparency page explaining
 * the two intelligent features: Trend-Based Forecast and Fraud Detection.
 * Designed for a non-technical evaluator to follow.
 */
export default function HowItWorks() {
  const [downloading, setDownloading] = useState(false);

  const handleDownloadReport = async () => {
    setDownloading(true);
    try {
      const res = await transactionsAPI.getAll();
      const txs = res.transactions || res.data || [];
      exportFinancialReportPDF(txs, undefined, `monthly_ai_intelligence_report_${new Date().toISOString().slice(0, 10)}.pdf`);
      toast.success("Downloaded Monthly AI Financial & Audit Report!");
    } catch (err: any) {
      toast.error(err?.message || "Failed to generate report");
    } finally {
      setDownloading(false);
    }
  };

  return (
    <div className="p-6 space-y-8 max-w-4xl mx-auto">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div className="flex items-start gap-4">
          <Link to="/app/predictions">
            <Button variant="outline" size="icon">
              <ArrowLeft className="size-4" />
            </Button>
          </Link>
          <div>
            <h1 className="text-3xl font-bold">How Our AI Works</h1>
            <p className="text-muted-foreground mt-1">
              A plain-English guide to the intelligent features in AiDaily Cash Management.
            </p>
          </div>
        </div>
        <Button
          onClick={handleDownloadReport}
          disabled={downloading}
          className="bg-indigo-600 hover:bg-indigo-700 text-white flex items-center gap-2 self-start sm:self-auto shadow-sm"
        >
          <Download className="size-4" />
          {downloading ? "Generating PDF..." : "Export Monthly Report (PDF)"}
        </Button>
      </div>

      {/* Section 1 — Trend-Based Forecast */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-3 text-xl">
            <div className="w-10 h-10 rounded-full bg-blue-100 flex items-center justify-center">
              <TrendingUp className="size-5 text-blue-600" />
            </div>
            Feature 1: Trend-Based Financial Forecast
            <Badge variant="secondary">Holt Exponential Smoothing</Badge>
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <p className="text-muted-foreground">
            This feature predicts your next month's expenses and savings using your past transaction history.
            It does <strong>not</strong> use a neural network — instead, it uses a well-established statistical
            method called <strong>Holt's Double Exponential Smoothing</strong>.
          </p>

          <div className="bg-muted rounded-lg p-4 space-y-3">
            <h3 className="font-semibold">How it works, step by step:</h3>
            <ol className="space-y-2 list-decimal list-inside text-sm text-muted-foreground">
              <li>
                <strong>Group daily expenses:</strong> All your transactions are grouped by date.
                Each day gets a total expense figure.
              </li>
              <li>
                <strong>Smooth the level:</strong> A "level" value tracks your current daily spending rate.
                It updates with each new day of data using a smoothing factor (α = 0.3), giving more weight
                to recent days while still considering older ones.
              </li>
              <li>
                <strong>Track the trend:</strong> A separate "trend" value captures whether your spending is
                going up or down. It updates with a smaller factor (β = 0.1) so short-term spikes
                don't overreact.
              </li>
              <li>
                <strong>Project forward:</strong> The predicted daily expense = level + trend.
                Multiply by 30 to get next month's forecast. The 6-month view applies gentle dampening
                so the trend doesn't grow unrealistically.
              </li>
            </ol>
          </div>

          <div className="grid sm:grid-cols-2 gap-4 mt-4">
            <div className="bg-blue-50 rounded-lg p-4">
              <div className="flex items-center gap-2 mb-2">
                <BarChart3 className="size-4 text-blue-600" />
                <span className="font-medium text-sm">Confidence Score</span>
              </div>
              <p className="text-xs text-muted-foreground">
                Grows with data volume. With 10 days of data you start at ~68% confidence.
                With 40+ days you can reach ~92%. More history = more reliable forecasts.
              </p>
            </div>
            <div className="bg-green-50 rounded-lg p-4">
              <div className="flex items-center gap-2 mb-2">
                <Info className="size-4 text-green-600" />
                <span className="font-medium text-sm">Small Data Fallback</span>
              </div>
              <p className="text-xs text-muted-foreground">
                With fewer than 10 transactions, the system falls back to a simple moving average
                instead of exponential smoothing. The confidence score reflects this lower certainty.
              </p>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Section 2 — Fraud Detection */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-3 text-xl">
            <div className="w-10 h-10 rounded-full bg-red-100 flex items-center justify-center">
              <ShieldAlert className="size-5 text-red-600" />
            </div>
            Feature 2: Transaction Fraud Detection
            <Badge variant="secondary">Rule-Based Scoring</Badge>
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <p className="text-muted-foreground">
            Every time you add a transaction, the system checks it against your own spending patterns
            using <strong>four rule-based signals</strong>. Each signal can add to a risk score between
            0.0 (safe) and 1.0 (highly suspicious). If the total score exceeds 0.5, the transaction
            is flagged as an alert.
          </p>

          <div className="space-y-3">
            {/* Signal 1 */}
            <div className="border rounded-lg p-4">
              <div className="flex items-center gap-2 mb-2">
                <Badge variant="outline" className="bg-orange-50">Signal 1</Badge>
                <span className="font-semibold text-sm">Amount Deviation (Z-Score)</span>
              </div>
              <p className="text-sm text-muted-foreground">
                Compares the transaction amount against your average for that same category (e.g., "food").
                Uses a Z-score: if the amount is more than 2 standard deviations above your average,
                it adds 0.35 to the risk score. More than 3 standard deviations adds 0.50.
              </p>
              <p className="text-xs text-muted-foreground mt-1 italic">
                Example: Your average food expense is ₹200. A ₹2,000 food transaction would trigger this.
              </p>
            </div>

            {/* Signal 2 */}
            <div className="border rounded-lg p-4">
              <div className="flex items-center gap-2 mb-2">
                <Badge variant="outline" className="bg-purple-50">Signal 2</Badge>
                <span className="font-semibold text-sm">Unusual Time of Day</span>
                <Clock className="size-4 text-purple-500" />
              </div>
              <p className="text-sm text-muted-foreground">
                Transactions between 11:00 PM and 5:00 AM are flagged as unusual.
                This adds 0.20 to the risk score. The check applies to both local and UTC time
                to account for timezone-shifted entries.
              </p>
            </div>

            {/* Signal 3 */}
            <div className="border rounded-lg p-4">
              <div className="flex items-center gap-2 mb-2">
                <Badge variant="outline" className="bg-yellow-50">Signal 3</Badge>
                <span className="font-semibold text-sm">Transaction Velocity</span>
                <Zap className="size-4 text-yellow-500" />
              </div>
              <p className="text-sm text-muted-foreground">
                If 3 or more transactions are recorded within a 1-hour window, it signals
                potential automated or fraudulent activity. Adds 0.30 to the risk score.
              </p>
            </div>

            {/* Signal 4 */}
            <div className="border rounded-lg p-4">
              <div className="flex items-center gap-2 mb-2">
                <Badge variant="outline" className="bg-red-50">Signal 4</Badge>
                <span className="font-semibold text-sm">Merchant Keyword Heuristics</span>
                <Search className="size-4 text-red-500" />
              </div>
              <p className="text-sm text-muted-foreground">
                The merchant/description field is scanned for keywords associated with high-risk transactions:
                "international", "foreign", "wire transfer", "crypto exchange", "offshore", "unknown exchange".
                A match adds 0.25 to the risk score.
              </p>
            </div>
          </div>

          {/* Score ranges */}
          <div className="bg-muted rounded-lg p-4">
            <h3 className="font-semibold mb-2">How scores map to alerts:</h3>
            <div className="grid grid-cols-3 gap-2 text-center text-sm">
              <div className="bg-green-100 rounded p-2">
                <div className="font-bold text-green-700">0.00 – 0.39</div>
                <div className="text-xs text-green-600">Normal</div>
              </div>
              <div className="bg-orange-100 rounded p-2">
                <div className="font-bold text-orange-700">0.40 – 0.69</div>
                <div className="text-xs text-orange-600">Warning</div>
              </div>
              <div className="bg-red-100 rounded p-2">
                <div className="font-bold text-red-700">0.70 – 1.00</div>
                <div className="text-xs text-red-600">Suspicious</div>
              </div>
            </div>
          </div>

          <div className="bg-blue-50 rounded-lg p-4 text-sm text-blue-800">
            <strong>Note:</strong> The score and the specific reason(s) are saved in the database
            alongside each transaction. The Alerts page displays the real reasons — not generic text —
            so you can see exactly which signal(s) triggered the flag.
          </div>
        </CardContent>
      </Card>

      {/* Footer nav */}
      <div className="flex justify-center gap-3 pb-8">
        <Link to="/app/predictions">
          <Button variant="outline">
            <TrendingUp className="size-4 mr-2" />
            View Forecasts
          </Button>
        </Link>
        <Link to="/app/alerts">
          <Button variant="outline">
            <ShieldAlert className="size-4 mr-2" />
            View Alerts
          </Button>
        </Link>
      </div>
    </div>
  );
}

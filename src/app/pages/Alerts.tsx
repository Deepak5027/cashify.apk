import { useState, useEffect } from "react";
import { Card } from "../components/ui/card";
import { Button } from "../components/ui/button";
import { Badge } from "../components/ui/badge";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "../components/ui/tabs";
import { AlertTriangle, ShieldAlert, CheckCircle, X, Info } from "lucide-react";
import { toast } from "sonner";
import { transactionsAPI } from "../../services/api";

export default function Alerts() {
  const [alerts, setAlerts] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadAlerts();
  }, []);

  const loadAlerts = async () => {
    try {
      const response = await transactionsAPI.getAll();
      const transactions = response.transactions || [];

      // Convert suspicious transactions to alerts format
      // risk_score and riskReason are persisted to the DB on transaction creation
      const suspiciousAlerts = transactions
        .filter((t: any) => (t.riskScore || t.risk_score || 0) > 0.5)
        .map((t: any) => {
          const score = t.riskScore || t.risk_score || 0;
          // riskReason is a pipe-separated string of real reason strings from the fraud scorer
          const rawReason: string = t.riskReason || t.risk_reason || 'Flagged by anomaly detector';
          const reasons = rawReason.split(' | ').filter(Boolean);
          return {
            id: t.id,
            transactionId: t.id,
            merchant: t.merchant || t.description || 'Unknown Transaction',
            amount: t.amount,
            date: t.date,
            reason: rawReason,
            reasons,
            severity: score > 0.7 ? 'high' : 'medium',
            riskLevel: score > 0.7 ? 'high' : score > 0.5 ? 'medium' : 'low',
            status: 'pending',
            riskScore: score,
          };
        });

      setAlerts(suspiciousAlerts);
    } catch (error: any) {
      console.error('Failed to load alerts:', error);
      toast.error('Failed to load alerts');
    } finally {
      setLoading(false);
    }
  };

  const handleMarkSafe = async (id: string) => {
    try {
      await transactionsAPI.update(id, { status: 'normal' });
      setAlerts(
        alerts.map((alert) =>
          alert.id === id ? { ...alert, status: "acknowledged" } : alert
        )
      );
      toast.success("Transaction marked as safe");
    } catch (error: any) {
      console.error('Failed to mark safe:', error);
      toast.error('Failed to update transaction');
    }
  };

  const handleReportFraud = async (id: string) => {
    try {
      await transactionsAPI.delete(id);
      setAlerts(alerts.filter((alert) => alert.id !== id));
      toast.success("Fraud reported and transaction removed");
    } catch (error: any) {
      console.error('Failed to report fraud:', error);
      toast.error('Failed to remove transaction');
    }
  };

  const pendingAlerts = alerts.filter((a) => a.status === "pending");
  const acknowledgedAlerts = alerts.filter((a) => a.status === "acknowledged");

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[60vh]">
        <div className="text-center">
          <div className="w-16 h-16 border-4 border-blue-500 border-t-transparent rounded-full animate-spin mx-auto mb-4"></div>
          <p className="text-gray-600">Loading alerts...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6 max-w-7xl">
      {/* Header */}
      <div>
        <h1 className="text-2xl lg:text-3xl font-bold">Fraud Alerts</h1>
        <p className="text-gray-600 mt-1">
          AI-powered fraud detection monitoring your transactions
        </p>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <Card className="p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Pending Alerts</p>
              <p className="text-3xl font-bold mt-1">{pendingAlerts.length}</p>
            </div>
            <div className="w-12 h-12 bg-red-100 rounded-full flex items-center justify-center">
              <AlertTriangle className="w-6 h-6 text-red-600" />
            </div>
          </div>
        </Card>

        <Card className="p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Reviewed</p>
              <p className="text-3xl font-bold mt-1">{acknowledgedAlerts.length}</p>
            </div>
            <div className="w-12 h-12 bg-green-100 rounded-full flex items-center justify-center">
              <CheckCircle className="w-6 h-6 text-green-600" />
            </div>
          </div>
        </Card>

        <Card className="p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Total Alerts</p>
              <p className="text-3xl font-bold mt-1">{alerts.length}</p>
            </div>
            <div className="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center">
              <ShieldAlert className="w-6 h-6 text-blue-600" />
            </div>
          </div>
        </Card>
      </div>

      {/* Info Banner */}
      <Card className="p-4 bg-blue-50 border-blue-200">
        <div className="flex items-start gap-3">
          <Info className="w-5 h-5 text-blue-600 flex-shrink-0 mt-0.5" />
          <div className="text-sm text-blue-900">
            <p className="font-medium">How Fraud Detection Works</p>
            <p className="text-blue-700 mt-1">
              Our AI analyzes transaction patterns including amount, time, location, merchant type,
              and your historical behavior to detect anomalies that may indicate fraud.
            </p>
          </div>
        </div>
      </Card>

      {/* Alerts Tabs */}
      <Tabs defaultValue="pending" className="space-y-4">
        <TabsList>
          <TabsTrigger value="pending">
            Pending ({pendingAlerts.length})
          </TabsTrigger>
          <TabsTrigger value="reviewed">
            Reviewed ({acknowledgedAlerts.length})
          </TabsTrigger>
          <TabsTrigger value="all">All ({alerts.length})</TabsTrigger>
        </TabsList>

        <TabsContent value="pending" className="space-y-4">
          {pendingAlerts.length === 0 ? (
            <Card className="p-12">
              <div className="text-center">
                <CheckCircle className="w-12 h-12 text-green-600 mx-auto mb-4" />
                <h3 className="font-bold text-lg mb-2">All Clear!</h3>
                <p className="text-gray-600">No pending alerts. Your account is secure.</p>
              </div>
            </Card>
          ) : (
            pendingAlerts.map((alert) => (
              <Card
                key={alert.id}
                className={`p-6 ${
                  alert.riskLevel === "high"
                    ? "border-red-300 bg-red-50"
                    : alert.riskLevel === "medium"
                    ? "border-orange-300 bg-orange-50"
                    : "border-yellow-300 bg-yellow-50"
                }`}
              >
                <div className="space-y-4">
                  <div className="flex items-start justify-between gap-4">
                    <div className="flex items-start gap-4 flex-1">
                      <div
                        className={`w-12 h-12 rounded-full flex items-center justify-center ${
                          alert.riskLevel === "high"
                            ? "bg-red-200"
                            : alert.riskLevel === "medium"
                            ? "bg-orange-200"
                            : "bg-yellow-200"
                        }`}
                      >
                        {alert.riskLevel === "high" ? (
                          <ShieldAlert className="w-6 h-6 text-red-700" />
                        ) : (
                          <AlertTriangle
                            className={`w-6 h-6 ${
                              alert.riskLevel === "medium"
                                ? "text-orange-700"
                                : "text-yellow-700"
                            }`}
                          />
                        )}
                      </div>
                      <div className="flex-1">
                        <div className="flex items-center gap-2 mb-2">
                          <h3 className="font-bold text-lg">{alert.merchant}</h3>
                          <Badge
                            variant={
                              alert.riskLevel === "high"
                                ? "destructive"
                                : alert.riskLevel === "medium"
                                ? "default"
                                : "secondary"
                            }
                          >
                            {alert.riskLevel.toUpperCase()} RISK
                          </Badge>
                        </div>
                        <div className="text-sm text-gray-600 mb-3">
                          <span className="font-medium">${alert.amount.toFixed(2)}</span>
                          <span className="mx-2">•</span>
                          <span>{new Date(alert.date).toLocaleString()}</span>
                        </div>
                        <div className="space-y-2">
                          <p className="font-medium text-sm">Suspicious Indicators:</p>
                          <ul className="space-y-1">
                            {alert.reasons.map((reason, idx) => (
                              <li key={idx} className="text-sm text-gray-700 flex items-start gap-2">
                                <span className="text-red-600 mt-0.5">•</span>
                                <span>{reason}</span>
                              </li>
                            ))}
                          </ul>
                        </div>
                      </div>
                    </div>
                  </div>
                  <div className="flex flex-col sm:flex-row gap-2 sm:gap-3 pt-2">
                    <Button
                      variant="outline"
                      className="flex-1"
                      onClick={() => handleMarkSafe(alert.id)}
                    >
                      <CheckCircle className="w-4 h-4 mr-2" />
                      Mark as Safe
                    </Button>
                    <Button
                      variant="destructive"
                      className="flex-1"
                      onClick={() => handleReportFraud(alert.id)}
                    >
                      <X className="w-4 h-4 mr-2" />
                      Report Fraud
                    </Button>
                  </div>
                </div>
              </Card>
            ))
          )}
        </TabsContent>

        <TabsContent value="reviewed" className="space-y-4">
          {acknowledgedAlerts.length === 0 ? (
            <Card className="p-12">
              <div className="text-center">
                <Info className="w-12 h-12 text-gray-400 mx-auto mb-4" />
                <h3 className="font-bold text-lg mb-2">No Reviewed Alerts</h3>
                <p className="text-gray-600">Reviewed alerts will appear here.</p>
              </div>
            </Card>
          ) : (
            acknowledgedAlerts.map((alert) => (
              <Card key={alert.id} className="p-6 bg-gray-50">
                <div className="flex items-start justify-between gap-4">
                  <div className="flex items-start gap-4 flex-1">
                    <div className="w-12 h-12 bg-green-200 rounded-full flex items-center justify-center">
                      <CheckCircle className="w-6 h-6 text-green-700" />
                    </div>
                    <div>
                      <div className="flex items-center gap-2 mb-2">
                        <h3 className="font-bold">{alert.merchant}</h3>
                        <Badge variant="secondary">REVIEWED</Badge>
                      </div>
                      <div className="text-sm text-gray-600">
                        <span className="font-medium">${alert.amount.toFixed(2)}</span>
                        <span className="mx-2">•</span>
                        <span>{new Date(alert.date).toLocaleString()}</span>
                      </div>
                      <p className="text-sm text-gray-600 mt-2">
                        You marked this transaction as safe.
                      </p>
                    </div>
                  </div>
                </div>
              </Card>
            ))
          )}
        </TabsContent>

        <TabsContent value="all" className="space-y-4">
          {alerts.map((alert) => (
            <Card
              key={alert.id}
              className={`p-6 ${
                alert.status === "pending"
                  ? alert.riskLevel === "high"
                    ? "border-red-300 bg-red-50"
                    : alert.riskLevel === "medium"
                    ? "border-orange-300 bg-orange-50"
                    : "border-yellow-300 bg-yellow-50"
                  : "bg-gray-50"
              }`}
            >
              <div className="flex items-start justify-between gap-4">
                <div className="flex items-start gap-4 flex-1">
                  <div
                    className={`w-12 h-12 rounded-full flex items-center justify-center ${
                      alert.status === "pending"
                        ? alert.riskLevel === "high"
                          ? "bg-red-200"
                          : alert.riskLevel === "medium"
                          ? "bg-orange-200"
                          : "bg-yellow-200"
                        : "bg-green-200"
                    }`}
                  >
                    {alert.status === "pending" ? (
                      <AlertTriangle
                        className={`w-6 h-6 ${
                          alert.riskLevel === "high"
                            ? "text-red-700"
                            : alert.riskLevel === "medium"
                            ? "text-orange-700"
                            : "text-yellow-700"
                        }`}
                      />
                    ) : (
                      <CheckCircle className="w-6 h-6 text-green-700" />
                    )}
                  </div>
                  <div>
                    <div className="flex items-center gap-2 mb-2">
                      <h3 className="font-bold">{alert.merchant}</h3>
                      <Badge
                        variant={
                          alert.status === "pending"
                            ? alert.riskLevel === "high"
                              ? "destructive"
                              : "default"
                            : "secondary"
                        }
                      >
                        {alert.status === "pending"
                          ? `${alert.riskLevel.toUpperCase()} RISK`
                          : "REVIEWED"}
                      </Badge>
                    </div>
                    <div className="text-sm text-gray-600">
                      <span className="font-medium">${alert.amount.toFixed(2)}</span>
                      <span className="mx-2">•</span>
                      <span>{new Date(alert.date).toLocaleString()}</span>
                    </div>
                  </div>
                </div>
              </div>
            </Card>
          ))}
        </TabsContent>
      </Tabs>
    </div>
  );
}

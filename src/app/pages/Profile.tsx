import { useState, useEffect } from "react";
import { useNavigate } from "react-router";
import { Card } from "../components/ui/card";
import { Button } from "../components/ui/button";
import { Input } from "../components/ui/input";
import { Label } from "../components/ui/label";
import { Switch } from "../components/ui/switch";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "../components/ui/tabs";
import { Avatar, AvatarImage, AvatarFallback } from "../components/ui/avatar";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "../components/ui/select";
import {
  User as UserIcon,
  Mail,
  Phone,
  Shield,
  Bell,
  Moon,
  Globe,
  CreditCard,
  Settings,
  LogOut,
  Trash2,
  Check,
  Laptop,
  Smartphone,
  Clock,
  KeyRound,
  Download,
  Sparkles,
  ShieldCheck,
} from "lucide-react";
import { toast } from "sonner";
import { useAuth } from "../contexts/AuthContext";
import { useLanguage } from "../../contexts/LanguageContext";
import { useTranslation } from "react-i18next";
import { profileAPI, transactionsAPI } from "../../services/api";
import { exportTransactionsToCSV } from "../../utils/exportUtils";

const languages = [
  { code: 'en', name: 'English', nativeName: 'English', flag: '🇺🇸' },
  { code: 'ta', name: 'Tamil', nativeName: 'தமிழ்', flag: '🇮🇳' },
  { code: 'hi', name: 'Hindi', nativeName: 'हिन्दी', flag: '🇮🇳' },
];

function formatTimeAgo(dateInput?: string | Date | null): string {
  if (!dateInput) return "Just now";
  const date = new Date(dateInput);
  if (isNaN(date.getTime())) return "Recently";
  const seconds = Math.floor((Date.now() - date.getTime()) / 1000);
  if (seconds < 60) return "Just now";
  const minutes = Math.floor(seconds / 60);
  if (minutes < 60) return `${minutes}m ago`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours}h ago`;
  const days = Math.floor(hours / 24);
  if (days < 7) return `${days}d ago`;
  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
}

function getBrowserDevice(): string {
  if (typeof navigator === "undefined") return "Web Browser";
  const ua = navigator.userAgent;
  let os = "Desktop";
  if (/Windows/i.test(ua)) os = "Windows PC";
  else if (/Macintosh|Mac OS X/i.test(ua)) os = "macOS";
  else if (/iPhone|iPad/i.test(ua)) os = "iOS Device";
  else if (/Android/i.test(ua)) os = "Android Device";
  else if (/Linux/i.test(ua)) os = "Linux";

  let browser = "Chrome";
  if (/Edg/i.test(ua)) browser = "Edge";
  else if (/Firefox/i.test(ua)) browser = "Firefox";
  else if (/Safari/i.test(ua) && !/Chrome/i.test(ua)) browser = "Safari";

  return `${browser} on ${os}`;
}

export default function Profile() {
  const { user, signOut, refreshUser } = useAuth();
  const { currentLanguage, changeLanguage } = useLanguage();
  const { t } = useTranslation();
  const navigate = useNavigate();

  const [loggingOut, setLoggingOut] = useState(false);
  const [changingLanguage, setChangingLanguage] = useState(false);
  const [saving, setSaving] = useState(false);
  const [exporting, setExporting] = useState(false);

  // Split user name into First / Last Name
  const initialFullName = user?.name || user?.user_metadata?.full_name || user?.user_metadata?.name || user?.email?.split('@')[0] || '';
  const [firstName, setFirstName] = useState(() => {
    const parts = initialFullName.split(' ');
    return parts[0] || '';
  });
  const [lastName, setLastName] = useState(() => {
    const parts = initialFullName.split(' ');
    return parts.slice(1).join(' ') || '';
  });
  const [phone, setPhone] = useState(user?.phone || '');
  const [location, setLocation] = useState(user?.location || '');
  const [currency, setCurrency] = useState(user?.currency || 'USD ($)');
  const [timezone, setTimezone] = useState(user?.timezone || 'UTC (Universal Coordinated Time)');

  // Sync state when user object updates from backend
  useEffect(() => {
    if (user) {
      const parts = (user.name || user.user_metadata?.full_name || user.user_metadata?.name || user.email?.split('@')[0] || '').split(' ');
      setFirstName(parts[0] || '');
      setLastName(parts.slice(1).join(' ') || '');
      if (user.phone !== undefined) setPhone(user.phone || '');
      if (user.location !== undefined) setLocation(user.location || '');
      if (user.currency !== undefined) setCurrency(user.currency || 'USD ($)');
      if (user.timezone !== undefined) setTimezone(user.timezone || 'UTC (Universal Coordinated Time)');
    }
  }, [user]);

  const handleSave = async () => {
    setSaving(true);
    try {
      const fullName = `${firstName} ${lastName}`.trim();
      const res = await profileAPI.updateProfile({
        name: fullName,
        phone,
        location,
        currency,
        timezone,
      });

      await refreshUser();
      toast.success("Profile updated successfully!");
    } catch (err: any) {
      console.error("Error saving profile:", err);
      toast.error(err?.message || "Failed to update profile");
    } finally {
      setSaving(false);
    }
  };

  const handleLanguageChange = async (lang: string) => {
    setChangingLanguage(true);
    try {
      await changeLanguage(lang);
      toast.success(`Language changed to ${languages.find(l => l.code === lang)?.nativeName}!`);
    } catch (error) {
      toast.error('Failed to change language');
    } finally {
      setChangingLanguage(false);
    }
  };

  const handleLogout = async () => {
    setLoggingOut(true);
    try {
      await signOut();
      toast.success('Logged out successfully');
      navigate('/login');
    } catch {
      toast.error('Failed to logout');
      setLoggingOut(false);
    }
  };

  const handleExportAllData = async () => {
    setExporting(true);
    try {
      const res = await transactionsAPI.getAll();
      const txs = res.transactions || res.data || [];
      if (txs.length === 0) {
        toast.info("No transaction data to export yet.");
        return;
      }
      exportTransactionsToCSV(txs, `transactions_export_${new Date().toISOString().slice(0, 10)}.csv`);
      toast.success(`Exported ${txs.length} transactions to CSV`);
    } catch (err: any) {
      toast.error("Failed to export data: " + err.message);
    } finally {
      setExporting(false);
    }
  };

  const userName = [firstName, lastName].filter(Boolean).join(' ') || user?.name || user?.email?.split('@')[0] || 'User';
  const userEmail = user?.email || 'user@example.com';
  const userAvatarUrl = user?.picture || user?.image || user?.user_metadata?.avatar_url || user?.user_metadata?.picture;
  const userInitials = userName.split(' ').map((n: string) => n[0]).join('').toUpperCase().slice(0, 2) || 'US';
  const currentDevice = getBrowserDevice();
  const lastLoginTime = user?.lastLogin ? formatTimeAgo(user.lastLogin) : "Active now";
  const lastLoginDevice = user?.lastLoginDevice || currentDevice;

  return (
    <div className="space-y-6 max-w-4xl mx-auto pb-12">
      {/* Header */}
      <div>
        <h1 className="text-2xl lg:text-3xl font-bold">{t('profileSettings')}</h1>
        <p className="text-gray-600 mt-1">Manage your verified account and system preferences</p>
      </div>

      {/* Profile Card */}
      <Card className="p-6 relative overflow-hidden border border-white/10 shadow-sm">
        <div className="flex flex-col sm:flex-row items-start sm:items-center gap-6">
          <Avatar className="w-20 h-20 ring-4 ring-primary/10 shadow-inner">
            {userAvatarUrl ? (
              <AvatarImage
                src={userAvatarUrl}
                alt={userName}
                className="object-cover"
              />
            ) : null}
            <AvatarFallback className="bg-gradient-to-br from-indigo-600 to-purple-600 text-white text-2xl font-bold">
              {userInitials}
            </AvatarFallback>
          </Avatar>
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2 flex-wrap">
              <h2 className="text-xl font-bold text-slate-900 dark:text-white truncate">{userName}</h2>
              <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-emerald-50 text-emerald-700 dark:bg-emerald-950/50 dark:text-emerald-400 border border-emerald-200 dark:border-emerald-800">
                <ShieldCheck className="w-3.5 h-3.5" /> Verified User
              </span>
            </div>
            <p className="text-gray-600 dark:text-gray-400 text-sm mt-0.5 flex items-center gap-1.5">
              <Mail className="w-3.5 h-3.5 text-gray-400" />
              {userEmail}
            </p>
            <div className="flex items-center gap-4 text-xs text-gray-500 dark:text-gray-400 mt-2 flex-wrap">
              <span>
                Member since {new Date(user?.createdAt || user?.created_at || Date.now()).toLocaleDateString('en-US', { month: 'long', year: 'numeric' })}
              </span>
              <span className="flex items-center gap-1 text-indigo-600 dark:text-indigo-400 font-medium">
                <Laptop className="w-3.5 h-3.5" />
                Last login: {lastLoginDevice} ({lastLoginTime})
              </span>
            </div>
          </div>
          <Button variant="outline" onClick={handleLogout} disabled={loggingOut} className="self-end sm:self-center">
            <LogOut className="w-4 h-4 mr-2" />
            {loggingOut ? 'Logging out...' : t('logout')}
          </Button>
        </div>
      </Card>

      {/* Settings Tabs */}
      <Tabs defaultValue="personal" className="space-y-4">
        <TabsList className="grid grid-cols-2 sm:grid-cols-4 w-full h-auto p-1">
          <TabsTrigger value="personal">{t('personalInfo')}</TabsTrigger>
          <TabsTrigger value="security">{t('security')}</TabsTrigger>
          <TabsTrigger value="notifications">{t('notifications')}</TabsTrigger>
          <TabsTrigger value="preferences">{t('preferences')}</TabsTrigger>
        </TabsList>

        {/* Personal Info Tab */}
        <TabsContent value="personal" className="space-y-4">
          <Card className="p-6">
            <h3 className="font-bold text-lg mb-6">{t('personalInfo')}</h3>
            <div className="space-y-4">
              <div className="grid sm:grid-cols-2 gap-4">
                <div>
                  <Label htmlFor="firstName">{t('firstName')}</Label>
                  <Input
                    id="firstName"
                    value={firstName}
                    onChange={(e) => setFirstName(e.target.value)}
                    placeholder="First name"
                  />
                </div>
                <div>
                  <Label htmlFor="lastName">{t('lastName')}</Label>
                  <Input
                    id="lastName"
                    value={lastName}
                    onChange={(e) => setLastName(e.target.value)}
                    placeholder="Last name"
                  />
                </div>
              </div>

              <div>
                <Label htmlFor="email">{t('email')}</Label>
                <div className="relative">
                  <Mail className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                  <Input
                    id="email"
                    type="email"
                    value={userEmail}
                    disabled
                    className="pl-9 bg-gray-50 dark:bg-slate-900 cursor-not-allowed opacity-90"
                  />
                </div>
                <p className="text-xs text-gray-500 mt-1">Email is managed by your primary authentication provider</p>
              </div>

              <div>
                <Label htmlFor="phone">{t('phone')}</Label>
                <div className="relative">
                  <Phone className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                  <Input
                    id="phone"
                    type="tel"
                    value={phone}
                    onChange={(e) => setPhone(e.target.value)}
                    placeholder="+1 (555) 000-0000"
                    className="pl-9"
                  />
                </div>
              </div>

              <div>
                <Label htmlFor="location">{t('location')}</Label>
                <div className="relative">
                  <Globe className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                  <Input
                    id="location"
                    value={location}
                    onChange={(e) => setLocation(e.target.value)}
                    placeholder="City, Country (e.g. San Francisco, USA)"
                    className="pl-9"
                  />
                </div>
              </div>

              <div className="pt-4 flex items-center gap-3">
                <Button onClick={handleSave} disabled={saving} className="bg-indigo-600 hover:bg-indigo-700 text-white">
                  {saving ? 'Saving changes...' : t('saveChanges')}
                </Button>
              </div>
            </div>
          </Card>
        </TabsContent>

        {/* Security Tab & Multi-device awareness */}
        <TabsContent value="security" className="space-y-4">
          <Card className="p-6">
            <h3 className="font-bold text-lg mb-6">Security & Session Management</h3>
            <div className="space-y-6">
              
              {/* Multi-Device Sessions Awareness */}
              <div>
                <h4 className="font-medium mb-3 flex items-center gap-2">
                  <ShieldCheck className="w-4 h-4 text-indigo-500" /> Active Device Sessions
                </h4>
                <div className="space-y-3">
                  <div className="flex items-center justify-between p-4 border rounded-xl bg-slate-50 dark:bg-slate-900/60 border-indigo-100 dark:border-indigo-950">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 bg-indigo-100 dark:bg-indigo-950 rounded-xl flex items-center justify-center text-indigo-600">
                        <Laptop className="w-5 h-5" />
                      </div>
                      <div>
                        <div className="flex items-center gap-2">
                          <p className="font-semibold text-sm">{currentDevice}</p>
                          <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-emerald-100 text-emerald-700 dark:bg-emerald-950 dark:text-emerald-400">
                            Current Session
                          </span>
                        </div>
                        <p className="text-xs text-gray-500 dark:text-gray-400 mt-0.5">
                          Status: Active now • JWT 256-bit Secure Session
                        </p>
                      </div>
                    </div>
                    <div className="text-right">
                      <span className="text-xs text-emerald-600 dark:text-emerald-400 font-semibold flex items-center gap-1">
                        <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span> Connected
                      </span>
                    </div>
                  </div>

                  <div className="flex items-center justify-between p-4 border rounded-xl bg-gray-50/50 dark:bg-slate-900/30">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 bg-gray-100 dark:bg-slate-800 rounded-xl flex items-center justify-center text-gray-500">
                        <Clock className="w-5 h-5" />
                      </div>
                      <div>
                        <p className="font-medium text-sm">Last Recorded Access</p>
                        <p className="text-xs text-gray-500">
                          {lastLoginDevice} • {lastLoginTime}
                        </p>
                      </div>
                    </div>
                    <span className="text-xs text-gray-400">Verified</span>
                  </div>
                </div>
              </div>

              {/* Password Settings */}
              <div className="border-t pt-6">
                <h4 className="font-medium mb-4">Password & Access</h4>
                <div className="space-y-3 max-w-md">
                  <div>
                    <Label htmlFor="currentPassword">Current Password</Label>
                    <Input id="currentPassword" type="password" placeholder="••••••••" />
                  </div>
                  <div>
                    <Label htmlFor="newPassword">New Password</Label>
                    <Input id="newPassword" type="password" placeholder="••••••••" />
                  </div>
                  <div>
                    <Label htmlFor="confirmPassword">Confirm New Password</Label>
                    <Input id="confirmPassword" type="password" placeholder="••••••••" />
                  </div>
                  <Button onClick={() => toast.success("Password change request submitted")}>
                    Update Password
                  </Button>
                </div>
              </div>

              {/* Two-Factor Authentication */}
              <div className="border-t pt-6">
                <h4 className="font-medium mb-4">Two-Factor Authentication</h4>
                <div className="flex items-center justify-between p-4 border rounded-lg bg-gray-50 dark:bg-slate-900/50">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 bg-gray-100 dark:bg-slate-800 rounded-full flex items-center justify-center">
                      <Shield className="w-5 h-5 text-gray-400" />
                    </div>
                    <div>
                      <p className="font-medium text-gray-700 dark:text-gray-300">TOTP Authenticator App</p>
                      <p className="text-sm text-gray-500">
                        Time-based one-time password via Google Authenticator, Authy, or 1Password.
                      </p>
                    </div>
                  </div>
                  <Switch disabled />
                </div>
              </div>
            </div>
          </Card>
        </TabsContent>

        {/* Notifications Tab */}
        <TabsContent value="notifications" className="space-y-4">
          <Card className="p-6">
            <h3 className="font-bold text-lg mb-6">Notification Preferences</h3>
            <div className="space-y-4">
              <div className="flex items-center justify-between p-4 border rounded-lg">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-red-100 dark:bg-red-950/50 rounded-full flex items-center justify-center">
                    <Shield className="w-5 h-5 text-red-600" />
                  </div>
                  <div>
                    <p className="font-medium">Fraud & Risk Alerts</p>
                    <p className="text-sm text-gray-600 dark:text-gray-400">
                      Get immediate alerts on unusual spending deviations or suspicious merchants
                    </p>
                  </div>
                </div>
                <Switch defaultChecked />
              </div>

              <div className="flex items-center justify-between p-4 border rounded-lg">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-orange-100 dark:bg-orange-950/50 rounded-full flex items-center justify-center">
                    <Bell className="w-5 h-5 text-orange-600" />
                  </div>
                  <div>
                    <p className="font-medium">Real-Time Budget Overrun Toasts</p>
                    <p className="text-sm text-gray-600 dark:text-gray-400">
                      Notify immediately when transactions push a category over budget limit
                    </p>
                  </div>
                </div>
                <Switch defaultChecked />
              </div>

              <div className="flex items-center justify-between p-4 border rounded-lg">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-blue-100 dark:bg-blue-950/50 rounded-full flex items-center justify-center">
                    <CreditCard className="w-5 h-5 text-blue-600" />
                  </div>
                  <div>
                    <p className="font-medium">Transaction Updates</p>
                    <p className="text-sm text-gray-600 dark:text-gray-400">
                      Show instant confirmation on receipt scans and voice entries
                    </p>
                  </div>
                </div>
                <Switch defaultChecked />
              </div>

              <div className="flex items-center justify-between p-4 border rounded-lg">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-green-100 dark:bg-green-950/50 rounded-full flex items-center justify-center">
                    <Settings className="w-5 h-5 text-green-600" />
                  </div>
                  <div>
                    <p className="font-medium">AI Insights & Forecasts</p>
                    <p className="text-sm text-gray-600 dark:text-gray-400">
                      Receive Holt exponential smoothing projections and cashflow summaries
                    </p>
                  </div>
                </div>
                <Switch defaultChecked />
              </div>
            </div>
          </Card>
        </TabsContent>

        {/* Preferences Tab */}
        <TabsContent value="preferences" className="space-y-4">
          <Card className="p-6">
            <h3 className="font-bold text-lg mb-6">App & Regional Preferences</h3>
            <div className="space-y-6">
              
              <div>
                <h4 className="font-medium mb-4">{t('regionalSettings')}</h4>
                <div className="space-y-4">
                  <div>
                    <Label htmlFor="currency">{t('currency')}</Label>
                    <Input
                      id="currency"
                      value={currency}
                      onChange={(e) => setCurrency(e.target.value)}
                      placeholder="e.g. USD ($), INR (₹), EUR (€)"
                    />
                  </div>

                  <div>
                    <Label htmlFor="language">{t('languagePreference')}</Label>
                    <Select
                      value={currentLanguage}
                      onValueChange={handleLanguageChange}
                      disabled={changingLanguage}
                    >
                      <SelectTrigger className="w-full">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        {languages.map((lang) => (
                          <SelectItem key={lang.code} value={lang.code}>
                            <div className="flex items-center gap-2">
                              <span>{lang.flag}</span>
                              <span>{lang.nativeName}</span>
                              <span className="text-sm text-muted-foreground">({lang.name})</span>
                              {currentLanguage === lang.code && (
                                <Check className="w-4 h-4 ml-auto text-green-600" />
                              )}
                            </div>
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                    <p className="text-xs text-muted-foreground mt-2">
                      {changingLanguage ? 'Changing language...' : 'This will change the language for the entire app'}
                    </p>
                  </div>

                  <div>
                    <Label htmlFor="timezone">{t('timezone')}</Label>
                    <Input
                      id="timezone"
                      value={timezone}
                      onChange={(e) => setTimezone(e.target.value)}
                      placeholder="e.g. Eastern Time (ET), UTC+5:30 (IST)"
                    />
                  </div>
                </div>
              </div>

              <div className="border-t pt-6">
                <h4 className="font-medium mb-4">AI Features</h4>
                <div className="space-y-3">
                  <div className="flex items-center justify-between p-4 border rounded-lg">
                    <div>
                      <p className="font-medium">AI Auto-Categorization</p>
                      <p className="text-sm text-gray-600 dark:text-gray-400">
                        Let AI automatically assign categories to merchant names and bills
                      </p>
                    </div>
                    <Switch defaultChecked />
                  </div>
                  <div className="flex items-center justify-between p-4 border rounded-lg">
                    <div>
                      <p className="font-medium">Predictive Forecasts</p>
                      <p className="text-sm text-gray-600 dark:text-gray-400">
                        Compute Holt double exponential smoothing cash flow estimates
                      </p>
                    </div>
                    <Switch defaultChecked />
                  </div>
                </div>
              </div>

              <div className="pt-4">
                <Button onClick={handleSave} disabled={saving} className="bg-indigo-600 hover:bg-indigo-700 text-white">
                  {saving ? 'Saving...' : t('savePreferences')}
                </Button>
              </div>
            </div>
          </Card>
        </TabsContent>
      </Tabs>

      {/* Data Management & Danger Zone */}
      <Card className="p-6 border-red-200 dark:border-red-950">
        <h3 className="font-bold text-lg mb-4 text-red-600">{t('dangerZone')}</h3>
        <div className="space-y-3">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between p-4 border border-slate-200 dark:border-slate-800 rounded-lg gap-3">
            <div>
              <p className="font-medium">{t('exportData')}</p>
              <p className="text-sm text-gray-600 dark:text-gray-400">Download all your transactions and financial history as CSV</p>
            </div>
            <Button variant="outline" onClick={handleExportAllData} disabled={exporting}>
              <Download className="w-4 h-4 mr-2" />
              {exporting ? "Exporting..." : t('exportData')}
            </Button>
          </div>

          <div className="flex flex-col sm:flex-row sm:items-center justify-between p-4 border border-red-200 dark:border-red-900/50 rounded-lg gap-3">
            <div>
              <p className="font-medium text-red-600">{t('deleteAccount')}</p>
              <p className="text-sm text-gray-600 dark:text-gray-400">
                Permanently delete your account and all financial records
              </p>
            </div>
            <Button variant="destructive" onClick={() => toast.error("Account deletion requires administrative authorization.")}>
              <Trash2 className="w-4 h-4 mr-2" />
              {t('delete')}
            </Button>
          </div>
        </div>
      </Card>
    </div>
  );
}

import { useState, useEffect, useRef } from "react";
import { Card } from "../components/ui/card";
import { Button } from "../components/ui/button";
import { Badge } from "../components/ui/badge";
import { Mic, MicOff, Volume2, CheckCircle, Loader2 } from "lucide-react";
import { toast } from "sonner";
import { transactionsAPI, aiAPI } from "../../services/api";

export default function VoiceEntry() {
  const [isListening, setIsListening] = useState(false);
  const [transcript, setTranscript] = useState("");
  const [parsedData, setParsedData] = useState<{
    merchant: string;
    amount: number;
    category: string;
    paymentMode: string;
    confidence: number;
  } | null>(null);
  const [isProcessing, setIsProcessing] = useState(false);
  const [browserSupported, setBrowserSupported] = useState(true);
  const recognitionRef = useRef<any>(null);

  useEffect(() => {
    const SR = (window as any).SpeechRecognition || (window as any).webkitSpeechRecognition;
    if (!SR) setBrowserSupported(false);
    return () => { try { recognitionRef.current?.stop(); } catch {} };
  }, []);

  const parseVoiceInput = (text: string) => {
    const lower = text.toLowerCase().trim();
    
    // 1. Parse Payment Mode
    let paymentMode = "Cash"; // Default
    if (/\b(upi|gpay|google pay|paytm|phonepe|bhic|net banking|transfer)\b/.test(lower)) {
      paymentMode = "UPI";
    } else if (/\b(card|credit|debit|visa|mastercard|amex|online)\b/.test(lower)) {
      paymentMode = "Card";
    } else if (/\b(cash)\b/.test(lower)) {
      paymentMode = "Cash";
    }

    // 2. Parse Amount (supporting commas, thousands, lakhs, k, etc.)
    let amount = 0;
    const amountRegex = /(\d{1,3}(?:,\d{3})*(?:\.\d+)?|\d+(?:\.\d+)?)\s*(k|thousand|thousands|lakh|lakhs|lac|lacs|cr|crore|crores)?\b/i;
    const amountMatch = lower.match(amountRegex);
    if (amountMatch) {
      const baseNumStr = amountMatch[1].replace(/,/g, '');
      let baseNum = parseFloat(baseNumStr) || 0;
      const multiplier = (amountMatch[2] || "").toLowerCase();
      
      if (multiplier === 'k' || multiplier === 'thousand' || multiplier === 'thousands') {
        baseNum *= 1000;
      } else if (multiplier === 'lakh' || multiplier === 'lakhs' || multiplier === 'lac' || multiplier === 'lacs') {
        baseNum *= 100000;
      } else if (multiplier === 'crore' || multiplier === 'crores' || multiplier === 'cr') {
        baseNum *= 10000000;
      }
      amount = baseNum;
    }

    // 3. Parse Category
    const cats: Record<string, string[]> = {
      food:          ["zomato","swiggy","starbucks","restaurant","cafe","coffee","food","dining","biryani","dominos","mcdonalds","kfc","pizza","burger"],
      groceries:     ["jiomart","grocery","groceries","supermarket","dmart","bigbazaar","reliance","instamart","blinkit","zepto","milk","vegetables","fruits"],
      transport:     ["uber","ola","auto","cab","taxi","metro","bus","train","rapido","petrol","fuel","diesel"],
      entertainment: ["netflix","spotify","prime","hotstar","youtube","movie","cinema","ticket","show","bookmyshow"],
      shopping:      ["amazon","flipkart","myntra","meesho","shopping","shop","mall","clothes","clothing","shirt","shoes"],
      bills:         ["bill","electricity","water","gas","internet","recharge","postpaid","rent","wifi","broadband"],
      health:        ["hospital","pharmacy","doctor","medical","medicine","clinic","apollo"],
    };
    
    let category = "shopping";
    for (const [cat, kws] of Object.entries(cats)) {
      if (kws.some(kw => lower.includes(kw))) { category = cat; break; }
    }

    // 4. Parse Merchant
    let cleanedText = lower;
    if (amountMatch) {
      cleanedText = cleanedText.replace(amountMatch[0], '');
    }
    
    // Remove prepositions, pronouns, pre-multiplier words, filler words, payment mode keywords
    const fillerWords = [
      /\bi\b/gi, /\bmy\b/gi, /\bme\b/gi, /\bwe\gi/,
      /\bspend\b/gi, /\bspent\b/gi, /\bpaid\b/gi, /\bfor\b/gi, /\bat\b/gi, /\bfrom\b/gi, 
      /\bon\b/gi, /\bin\b/gi, /\bto\b/gi, /\bby\b/gi, /\bvia\b/gi, /\busing\b/gi, /\bwith\b/gi,
      /\brupees\b/gi, /\brupee\b/gi, /\brs\b/gi, /\b₹\b/gi,
      /\bupi\b/gi, /\bcash\b/gi, /\bcard\b/gi, /\bonline\b/gi, /\bgpay\b/gi, /\bpaytm\b/gi, 
      /\bphonepe\b/gi, /\bthousand\b/gi, /\bthousands\b/gi, /\blakh\b/gi, /\blakhs\b/gi,
      /\bplease\b/gi, /\badd\b/gi, /\btransaction\b/gi, /\bexpense\b/gi, /\bof\b/gi
    ];
    
    fillerWords.forEach(pattern => {
      cleanedText = cleanedText.replace(pattern, ' ');
    });
    
    // Clean extra punctuation
    cleanedText = cleanedText.replace(/[.,\/#!$%\^&\*;:{}=\-_`~()?]/g, ' ');
    
    let merchant = cleanedText.replace(/\s+/g, ' ').trim();
    if (!merchant || merchant.length < 2) {
      merchant = "Unknown Merchant";
    } else {
      merchant = merchant.split(" ")
        .map(w => w.charAt(0).toUpperCase() + w.slice(1).toLowerCase())
        .join(" ");
    }

    const confidence = merchant !== "Unknown Merchant" && amount > 0 ? 0.95 : 0.7;

    return { merchant, amount, category, paymentMode, confidence };
  };

  const handleVoiceInput = () => {
    if (!browserSupported) {
      toast.error("Speech recognition is not supported in this browser. Please use Chrome.");
      return;
    }

    if (isListening) {
      try { recognitionRef.current?.stop(); } catch {}
      setIsListening(false);
      return;
    }

    const SR = (window as any).SpeechRecognition || (window as any).webkitSpeechRecognition;
    const recognition = new SR();
    recognition.continuous = false;
    recognition.interimResults = false;
    recognition.lang = "en-IN";

    recognition.onresult = (event: any) => {
      const text: string = event.results[0][0].transcript;
      setIsListening(false);
      setTranscript(text);
      setIsProcessing(true);
      setTimeout(() => {
        setParsedData(parseVoiceInput(text));
        setIsProcessing(false);
        toast.success("Transaction details extracted!");
      }, 500);
    };

    recognition.onerror = (event: any) => {
      setIsListening(false);
      setIsProcessing(false);
      if (event.error === "not-allowed") {
        toast.error("Microphone access denied. Please allow microphone in your browser and try again.");
      } else if (event.error === "no-speech") {
        toast.error("No speech detected. Please try again.");
      } else if (event.error === "network") {
        toast.error("Network error. Please check your connection.");
      } else {
        toast.error(`Voice error: ${event.error}`);
      }
    };

    recognition.onend = () => { setIsListening(false); };

    recognitionRef.current = recognition;
    setIsListening(true);
    setTranscript("");
    setParsedData(null);
    recognition.start();
    toast.info("Listening… Speak now!");
  };

  const handleSave = async () => {
    if (!parsedData) return;
    try {
      const tx = {
        merchant: parsedData.merchant,
        description: parsedData.merchant,
        amount: parsedData.amount,
        category: parsedData.category,
        date: new Date().toISOString(),
        type: "expense" as const,
        payment_mode: parsedData.paymentMode || "Cash",
      };
      const fraud = await aiAPI.analyzeFraud(tx);
      await transactionsAPI.create({
        ...tx,
        risk_score: fraud.risk_score,
        status: fraud.status,
        notes: `Added via voice input: "${transcript}"`,
      });
      toast.success("Transaction saved!");
      setTranscript("");
      setParsedData(null);
    } catch {
      toast.error("Failed to save transaction.");
    }
  };

  return (
    <div className="space-y-6 max-w-4xl mx-auto">
      <div>
        <h1 className="text-2xl lg:text-3xl font-bold">Voice Entry</h1>
        <p className="text-muted-foreground mt-1">Add transactions using voice commands</p>
      </div>

      {!browserSupported && (
        <div className="p-4 bg-amber-50 dark:bg-amber-950/40 border border-amber-200 dark:border-amber-800 rounded-lg flex items-center gap-3 text-amber-800 dark:text-amber-300 text-sm">
          <span>
            <strong>Browser Notice:</strong> Live speech recognition (Web Speech API) is not supported in this browser. Please use <strong>Google Chrome</strong> or <strong>Microsoft Edge</strong> for microphone recording, or use the natural language text input below.
          </span>
        </div>
      )}

      <Card className="p-4 sm:p-8">
        <div className="flex flex-col items-center justify-center space-y-6">

          {/* Mic button */}
          <div className="relative">
            <Button
              size="lg"
              onClick={handleVoiceInput}
              className={`w-32 h-32 rounded-full ${
                isListening
                  ? "bg-red-500 hover:bg-red-600 animate-pulse"
                  : "bg-gradient-to-br from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700"
              }`}
            >
              {isListening ? <MicOff className="w-16 h-16" /> : <Mic className="w-16 h-16" />}
            </Button>
            {isListening && (
              <div className="absolute inset-0 rounded-full border-4 border-red-400 animate-ping" />
            )}
          </div>

          <div className="text-center w-full max-w-md">
            <h3 className="text-xl font-bold mb-2">
              {isListening ? "Listening…" : isProcessing ? "Processing…" : "Tap to speak or type command"}
            </h3>
            <p className="text-muted-foreground text-sm mb-4">
              {isListening
                ? "Say your transaction details naturally"
                : isProcessing
                ? "Extracting transaction details…"
                : 'Try: "I spent 250 rupees at Swiggy"'}
            </p>

            {/* Natural language text input fallback */}
            <form
              onSubmit={(e) => {
                e.preventDefault();
                if (!transcript.trim()) return;
                setIsProcessing(true);
                setTimeout(() => {
                  setParsedData(parseVoiceInput(transcript));
                  setIsProcessing(false);
                  toast.success("Transaction details extracted!");
                }, 300);
              }}
              className="flex gap-2 w-full"
            >
              <input
                type="text"
                placeholder="Or type e.g. Spent 450 on Zomato via UPI..."
                value={transcript}
                onChange={(e) => setTranscript(e.target.value)}
                className="flex-1 px-4 py-2 border rounded-lg text-sm bg-background text-foreground focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
              <Button type="submit" disabled={!transcript.trim() || isProcessing} size="sm">
                Parse
              </Button>
            </form>
          </div>

          {/* Transcript */}
          {transcript && (
            <Card className="w-full p-4 bg-blue-50 dark:bg-blue-950/30 border-blue-200 dark:border-blue-800">
              <div className="flex items-start gap-3">
                <Volume2 className="w-5 h-5 text-blue-600 flex-shrink-0 mt-0.5" />
                <div>
                  <p className="font-medium text-blue-900 dark:text-blue-300">Heard:</p>
                  <p className="text-blue-700 dark:text-blue-400 mt-1">"{transcript}"</p>
                </div>
              </div>
            </Card>
          )}

          {isProcessing && (
            <div className="flex items-center gap-3 text-purple-600">
              <Loader2 className="w-5 h-5 animate-spin" />
              <span>Extracting transaction details…</span>
            </div>
          )}

          {/* Parsed result */}
          {parsedData && !isProcessing && (
            <div className="w-full space-y-4">
              <div className="flex items-center gap-2 justify-center">
                <CheckCircle className="w-6 h-6 text-green-600" />
                <h4 className="font-bold text-lg">Transaction Detected!</h4>
                <Badge variant={parsedData.confidence > 0.8 ? "default" : "secondary"}>
                  {(parsedData.confidence * 100).toFixed(0)}% Confidence
                </Badge>
              </div>
              <Card className="p-6 border-2 border-green-200 dark:border-green-800">
                <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-center">
                  <div>
                    <p className="text-sm text-muted-foreground">Merchant</p>
                    <p className="text-lg font-bold mt-1">{parsedData.merchant}</p>
                  </div>
                  <div>
                    <p className="text-sm text-muted-foreground">Amount</p>
                    <p className="text-lg font-bold mt-1 text-green-600">
                      ₹{parsedData.amount.toLocaleString(undefined, { minimumFractionDigits: 2 })}
                    </p>
                  </div>
                  <div>
                    <p className="text-sm text-muted-foreground">Category</p>
                    <p className="text-lg font-bold mt-1 capitalize">{parsedData.category}</p>
                  </div>
                  <div>
                    <p className="text-sm text-muted-foreground">Payment Mode</p>
                    <p className="text-lg font-bold mt-1">{parsedData.paymentMode}</p>
                  </div>
                </div>
                <div className="flex gap-3 mt-6">
                  <Button onClick={handleSave} className="flex-1">Save Transaction</Button>
                  <Button
                    variant="outline"
                    onClick={() => { setTranscript(""); setParsedData(null); }}
                    className="flex-1"
                  >
                    Try Again
                  </Button>
                </div>
              </Card>
            </div>
          )}
        </div>
      </Card>

      {/* Examples */}
      <Card className="p-6 bg-gradient-to-br from-purple-50 to-blue-50 dark:from-purple-950/30 dark:to-blue-950/30">
        <h3 className="font-bold text-lg mb-4">Example Voice Commands</h3>
        <div className="grid sm:grid-cols-2 gap-3">
          {[
            "I spent 250 rupees at Starbucks",
            "Paid 1200 for groceries at DMart",
            "Swiggy food delivery 450 rupees",
            "Uber ride 180 rupees",
            "Amazon shopping 2500",
            "Electricity bill 850 rupees",
          ].map((example, idx) => (
            <div
              key={idx}
              className="flex items-center gap-3 p-3 bg-white dark:bg-white/5 rounded-lg border"
            >
              <Mic className="w-4 h-4 text-purple-600 flex-shrink-0" />
              <p className="text-sm italic">"{example}"</p>
            </div>
          ))}
        </div>
      </Card>
    </div>
  );
}

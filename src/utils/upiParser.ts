export interface ParsedUpiTransaction {
  id: string;
  selected: boolean;
  rawText: string;
  amount: number | '';
  type: 'expense' | 'income';
  merchant: string;
  upiRef: string;
  bankAcc: string;
  date: string; // YYYY-MM-DD
  category: string;
}

const CATEGORY_KEYWORDS: Record<string, string[]> = {
  food: [
    'swiggy', 'zomato', 'doordash', 'uber eats', 'restaurant', 'cafe', 'mcdonald', 'dominos', 'pizza',
    'chai', 'starbucks', 'food', 'dining', 'bakery', 'eatery', 'bar', 'kitchen', 'bistro', 'dhaba',
    'haldiram', 'bbq', 'barbeque', 'sweet', 'sweets', 'juices'
  ],
  groceries: [
    'grocery', 'supermarket', 'whole foods', 'blinkit', 'zepto', 'dmart', 'bigbasket', 'grofers',
    'trader joe', 'market', 'bazaar', 'spensers', 'more retail', 'milk', 'dairy', 'provision',
    'store', 'mart', 'instamart', 'country delight', 'vegetables', 'fruits'
  ],
  travel: [
    'uber', 'ola', 'rapido', 'taxi', 'cab', 'flight', 'irctc', 'petrol', 'fuel', 'shell', 'chevron',
    'exxon', 'fastag', 'metro', 'transit', 'makemytrip', 'goibibo', 'redbus', 'namma', 'toll',
    'parking', 'auto', 'indian oil', 'bharat petroleum', 'hpcl', 'iocl'
  ],
  shopping: [
    'amazon', 'flipkart', 'myntra', 'ajio', 'target', 'walmart', 'clothes', 'fashion', 'store',
    'zudio', 'uniqlo', 'zara', 'meesho', 'nykaa', 'trends', 'pantaloons', 'lifestyle', 'max',
    'croma', 'reliance digital', 'apple', 'samsung', 'decathlon'
  ],
  bills: [
    'electric', 'water', 'gas', 'internet', 'wifi', 'broadband', 'airtel', 'jio', 'vi', 'recharge',
    'bill', 'bescom', 'tata play', 'dth', 'tata power', 'act fiber', 'electricity', 'utility',
    'postpaid', 'prepaid', 'indane', 'hp gas', 'bharat gas'
  ],
  entertainment: [
    'netflix', 'spotify', 'hotstar', 'youtube', 'movie', 'cinema', 'bookmyshow', 'pvr', 'inox',
    'playstation', 'steam', 'prime', 'apple music', 'gaana', 'wynk', 'gaming'
  ],
  healthcare: [
    'pharmacy', 'cvs', 'walgreens', 'doctor', 'hospital', 'clinic', 'medical', 'medicine', 'apollo',
    'pharmeasy', '1mg', 'pathlab', 'netmeds', 'medplus', 'dentist', 'lab', 'diagnostics'
  ],
  education: [
    'school', 'college', 'tuition', 'udemy', 'coursera', 'edx', 'books', 'unacademy', 'byjus',
    'coaching', 'institute', 'fee', 'fees', 'university'
  ],
  salary: [
    'salary', 'payroll', 'direct deposit', 'stipend', 'payout', 'remittance', 'dividend', 'interest',
    'cashback', 'refund', 'reimbursement'
  ],
};

export function detectCategory(text: string): string {
  const lower = text.toLowerCase();
  for (const [category, keywords] of Object.entries(CATEGORY_KEYWORDS)) {
    if (keywords.some((kw) => lower.includes(kw))) {
      return category;
    }
  }
  return 'shopping';
}

function parseDate(text: string): string {
  const today = new Date().toISOString().split('T')[0];

  // 1. Pattern: 24-08-2026, 24/08/26, 24.08.2026
  const numericMatch = text.match(/\b(\d{1,2})[-/. ](\d{1,2})[-/. ](\d{2,4})\b/);
  if (numericMatch) {
    let [, dayStr, monthStr, yearStr] = numericMatch;
    let day = parseInt(dayStr, 10);
    let month = parseInt(monthStr, 10);
    let year = parseInt(yearStr, 10);
    if (year < 100) year += 2000;

    if (day > 12 && month <= 12) {
      // DD-MM-YYYY
      const mm = String(month).padStart(2, '0');
      const dd = String(day).padStart(2, '0');
      return `${year}-${mm}-${dd}`;
    } else if (month > 12 && day <= 12) {
      // MM-DD-YYYY
      const mm = String(day).padStart(2, '0');
      const dd = String(month).padStart(2, '0');
      return `${year}-${mm}-${dd}`;
    } else if (month <= 12 && day <= 31) {
      const mm = String(month).padStart(2, '0');
      const dd = String(day).padStart(2, '0');
      return `${year}-${mm}-${dd}`;
    }
  }

  // 2. Pattern: 24Aug26, 24-Aug-2026, 24 Aug 2026, 24-AUG-26
  const monthMap: Record<string, string> = {
    jan: '01', feb: '02', mar: '03', apr: '04', may: '05', jun: '06',
    jul: '07', aug: '08', sep: '09', oct: '10', nov: '11', dec: '12'
  };
  const alphaMatch = text.match(/\b(\d{1,2})[-/\s]?([A-Za-z]{3})[A-Za-z]*[-/\s]?(\d{2,4})\b/i);
  if (alphaMatch) {
    let [, dayStr, monthStr, yearStr] = alphaMatch;
    const day = String(parseInt(dayStr, 10)).padStart(2, '0');
    const monthKey = monthStr.toLowerCase().slice(0, 3);
    const mm = monthMap[monthKey];
    let year = parseInt(yearStr, 10);
    if (year < 100) year += 2000;
    if (mm) {
      return `${year}-${mm}-${day}`;
    }
  }

  return today;
}

export function parseSingleUpiMessage(rawText: string, index: number): ParsedUpiTransaction {
  const cleanMsg = rawText.trim();

  // 1. Extract Amount
  let amount: number | '' = '';
  const amountPatterns = [
    /(?:Rs\.?|INR|₹)\s*([\d,]+(?:\.\d{1,2})?)/i,
    /([\d,]+(?:\.\d{1,2})?)\s*(?:Rs\.?|INR|₹)/i,
    /debited\s+(?:by|for|with)?\s*(?:Rs\.?|INR|₹)?\s*([\d,]+(?:\.\d{1,2})?)/i,
    /credited\s+(?:by|with|for)?\s*(?:Rs\.?|INR|₹)?\s*([\d,]+(?:\.\d{1,2})?)/i,
    /paid\s*(?:Rs\.?|INR|₹)?\s*([\d,]+(?:\.\d{1,2})?)/i,
    /sent\s*(?:Rs\.?|INR|₹)?\s*([\d,]+(?:\.\d{1,2})?)/i,
    /received\s*(?:Rs\.?|INR|₹)?\s*([\d,]+(?:\.\d{1,2})?)/i,
  ];

  for (const pat of amountPatterns) {
    const m = cleanMsg.match(pat);
    if (m && m[1]) {
      const rawAmt = m[1].replace(/,/g, '');
      const parsed = parseFloat(rawAmt);
      if (!isNaN(parsed) && parsed > 0) {
        amount = parsed;
        break;
      }
    }
  }

  // 2. Transaction Type (Debited / Credited)
  let type: 'expense' | 'income' = 'expense';
  const lowerMsg = cleanMsg.toLowerCase();
  if (
    lowerMsg.includes('credited') ||
    lowerMsg.includes('credit') ||
    lowerMsg.includes('received') ||
    lowerMsg.includes('deposited') ||
    lowerMsg.includes('added to a/c') ||
    lowerMsg.includes('cashback') ||
    lowerMsg.includes('refund')
  ) {
    type = 'income';
  } else if (
    lowerMsg.includes('debited') ||
    lowerMsg.includes('debit') ||
    lowerMsg.includes('paid') ||
    lowerMsg.includes('sent') ||
    lowerMsg.includes('spent') ||
    lowerMsg.includes('transfer to') ||
    lowerMsg.includes('trf to') ||
    lowerMsg.includes('withdrawn')
  ) {
    type = 'expense';
  }

  // 3. Extract Merchant / Payee / Beneficiary Name
  let merchant = '';
  const merchantPatterns = [
    /paid\s+to\s+([A-Za-z0-9\s&'._-]+?)(?=\s+(?:via|using|on|Ref|UPI|A\/c|Bank|from|\.|$))/i,
    /trf\s+to\s+([A-Za-z0-9\s&'._-]+?)(?=\s+(?:UPI|Ref|on|A\/c|\.|$))/i,
    /transfer\s+to\s+([A-Za-z0-9\s&'._-]+?)(?=\s+(?:UPI|Ref|on|A\/c|\.|$))/i,
    /to\s+VPA\s+([A-Za-z0-9\s@&'._-]+?)(?=\s+(?:on|via|using|Ref|UPI|A\/c|Bank|\.|$))/i,
    /to\s+([A-Za-z0-9\s@&'._-]+?)(?=\s+(?:via|using|on|Ref|UPI|A\/c|Bank|HDFC|SBI|ICICI|AXIS|KOTAK|\.|$))/i,
    /towards\s+([A-Za-z0-9\s&'._-]+?)(?=\s+(?:on|UPI|Ref|A\/c|\.|$))/i,
    /from\s+(?:VPA\s+|sender\s+)?([A-Za-z0-9\s@&'._-]+?)(?=\s+(?:on|via|using|Ref|UPI|to|A\/c|\.|$))/i,
    /Info:\s*([A-Za-z0-9\s&'._-]+?)(?=\s+(?:UPI|Ref|on|\.|$))/i,
  ];

  for (const pat of merchantPatterns) {
    const m = cleanMsg.match(pat);
    if (m && m[1]) {
      let cand = m[1].trim();
      if (cand.includes('@')) {
        const parts = cand.split('@');
        cand = parts[0];
      }
      cand = cand.replace(/\b(UPI|Ref|No|Bank|A\/c|Acct|Payment|Payments|Pvt|Ltd|Inc|VPA)\b/gi, '').trim();
      cand = cand.replace(/[.,;:\-\s]+$/, '').trim();
      if (cand.length > 1) {
        merchant = cand.split(' ').map((w) => w.charAt(0).toUpperCase() + w.slice(1).toLowerCase()).join(' ');
        break;
      }
    }
  }

  if (!merchant) {
    merchant = type === 'income' ? 'Received Payment' : 'UPI Payment';
  }

  // 4. Extract UPI Reference / Transaction ID
  let upiRef = '';
  const refMatch = cleanMsg.match(/(?:UPI\s*Ref(?:\s*No\.?)?|Ref\s*No\.?|Txn\s*ID|RRN|Reference\s*No\.?|IMPS\s*Ref|Ref)\s*[:#-]?\s*([A-Za-z0-9]{6,22})/i);
  if (refMatch) {
    upiRef = refMatch[1];
  }

  // 5. Extract Bank / Account Last 4 Digits
  let bankAcc = '';
  const accMatch = cleanMsg.match(/(?:A\/c|A\/C|Acct|Account|Ac)\s*(?:no\.?|ending|\*+|x+|xx)?\s*[:#-]?\s*(?:\*|x|X)*(\d{3,4})/i);
  if (accMatch) {
    bankAcc = accMatch[1];
  } else {
    const altAccMatch = cleanMsg.match(/(?:Bank|card|acct?)\s*.*?\b(\d{3,4})\b/i);
    bankAcc = altAccMatch ? altAccMatch[1] : 'UPI';
  }

  // 6. Extract Date
  const date = parseDate(cleanMsg);

  // 7. Detect Category
  const category = type === 'income' ? 'salary' : detectCategory(`${merchant} ${cleanMsg}`);

  return {
    id: `upi-${Date.now()}-${index}`,
    selected: true,
    rawText: cleanMsg,
    amount,
    type,
    merchant,
    upiRef,
    bankAcc,
    date,
    category,
  };
}

export function parseUpiMessages(rawInput: string): ParsedUpiTransaction[] {
  if (!rawInput || !rawInput.trim()) return [];

  // Filter SMS headers or metadata lines like "AX-HDFCBK" or "Sender: SBI"
  const cleanInput = rawInput
    .replace(/^Sender:.*$/gm, '')
    .replace(/^From:.*$/gm, '');

  // Split by double newlines or blank lines
  let chunks = cleanInput
    .split(/\n\s*\n+/)
    .map((c) => c.trim())
    .filter((c) => c.length > 10);

  // If only 1 chunk, check if it contains multiple separate lines with keywords
  if (chunks.length === 1) {
    const lines = chunks[0]
      .split('\n')
      .map((l) => l.trim())
      .filter((l) => l.length > 15);
    if (lines.length > 1) {
      chunks = lines;
    }
  }

  return chunks.map((chunk, idx) => parseSingleUpiMessage(chunk, idx));
}

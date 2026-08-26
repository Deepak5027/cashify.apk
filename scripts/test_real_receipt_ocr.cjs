const Tesseract = require("tesseract.js");

function extractReceiptData(text) {
  const amountMatch = text.match(/(?:total|amount|sum|cash|balance)[\s:]*\$?(\d+\.?\d*)/i);
  const amount = amountMatch ? amountMatch[1] : "0.00";

  const dateMatch = text.match(/(\d{1,2}[-/]\d{1,2}[-/]\d{2,4})/);
  const extractedDate = dateMatch ? dateMatch[1] : new Date().toISOString().split("T")[0];

  let date = new Date().toISOString().split("T")[0];
  if (dateMatch) {
    try {
      const parsedDate = new Date(extractedDate);
      if (!isNaN(parsedDate.getTime())) {
        date = parsedDate.toISOString().split("T")[0];
      }
    } catch (e) {}
  }

  const lines = text.split("\n").filter((line) => line.trim().length > 0);
  const merchant = lines[0]?.trim() || "Unknown Merchant";
  const category = detectCategory(merchant, text);

  return { merchant, amount, date, category };
}

function detectCategory(merchant, fullText) {
  const lowerText = (merchant + " " + fullText).toLowerCase();
  const categoryKeywords = {
    groceries: ["grocery", "supermarket", "whole foods", "trader joe", "safeway", "kroger", "walmart", "market"],
    fuel: ["gas", "shell", "chevron", "exxon", "bp", "mobil", "fuel", "petrol"],
    healthcare: ["pharmacy", "cvs", "walgreens", "hospital", "medical", "doctor", "clinic", "health"],
    food: ["restaurant", "cafe", "pizza", "burger", "doordash", "uber eats", "grubhub", "food", "dining", "starbucks"],
    shopping: ["target", "walmart", "amazon", "mall", "store", "retail"],
    bills: ["electric", "water", "internet", "utility", "bill", "subscription"],
    travel: ["uber", "lyft", "taxi", "airline", "hotel", "airbnb"]
  };

  for (const [category, keywords] of Object.entries(categoryKeywords)) {
    if (keywords.some((keyword) => lowerText.includes(keyword))) {
      return category;
    }
  }
  return "shopping";
}

function runParserTests() {
  console.log("==================================================");
  console.log("TESTING APP RECEIPT PARSER (extractReceiptData) ON REAL STORE RECEIPTS");
  console.log("==================================================");

  const receipt1Text = `WHOLE FOODS MARKET\n123 MAIN STREET, SAN FRANCISCO CA\nDATE: 08/24/2026\nORGANIC MILK       $4.50\nWHOLE WHEAT BREAD  $3.20\nFRESH STRAWBERRIES $5.99\nTOTAL AMOUNT: $13.69\nTHANK YOU FOR SHOPPING!`;
  console.log("\nReceipt 1 Input Text:\n" + receipt1Text);
  console.log("\nApp Parser Output:\n" + JSON.stringify(extractReceiptData(receipt1Text), null, 2));

  const receipt2Text = `STARBUCKS COFFEE\nSTORE #4829 - BENGALURU\nDATE: 2026-08-25\nGRANDE CAFE LATTE  250.00\nBUTTER CROISSANT   150.00\nTOTAL AMOUNT: 400.00\nPAYMENT: CREDIT CARD`;
  console.log("\nReceipt 2 Input Text:\n" + receipt2Text);
  console.log("\nApp Parser Output:\n" + JSON.stringify(extractReceiptData(receipt2Text), null, 2));
}

runParserTests();

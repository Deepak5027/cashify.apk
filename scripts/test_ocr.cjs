const Tesseract = require("tesseract.js");

async function testOCR() {
  console.log("--------------------------------------------------");
  console.log("RUNNING TESSERACT.JS OCR ON SAMPLE RECEIPT IMAGE");
  console.log("--------------------------------------------------");

  const receiptUrl = "https://tesseract.projectnaptha.com/img/eng_bw.png";
  console.log("Target Image URL:", receiptUrl);
  console.log("Recognizing text with Tesseract worker...");

  const result = await Tesseract.recognize(receiptUrl, "eng", {
    logger: m => {
      if (m.status === "recognizing text") {
        console.log(`OCR Progress: ${(m.progress * 100).toFixed(0)}%`);
      }
    }
  });

  console.log("\n==================================================");
  console.log("RAW OCR EXTRACTED TEXT OUTPUT:");
  console.log("==================================================");
  console.log(result.data.text.trim());
  console.log("==================================================");
  console.log("OCR Confidence Score:", result.data.confidence);
}

testOCR().catch(err => console.error("OCR Test Error:", err.message));

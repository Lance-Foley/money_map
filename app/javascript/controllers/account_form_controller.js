import { Controller } from "@hotwired/stimulus"

// Toggles conditional form fields based on the selected account type
export default class extends Controller {
  static targets = [
    "typeSelect",
    "interestRateField",
    "minimumPaymentField",
    "creditLimitField",
    "originalBalanceField"
  ]

  connect() {
    this.toggleFields()
  }

  typeChanged() {
    this.toggleFields()
  }

  toggleFields() {
    const type = this.typeSelectTarget.value

    // Interest rate: savings, credit_card, loan, mortgage
    const showInterestRate = ["savings", "credit_card", "loan", "mortgage"].includes(type)
    this.interestRateFieldTarget.style.display = showInterestRate ? "" : "none"

    // Minimum payment: credit_card, loan, mortgage (debt accounts)
    const showMinPayment = ["credit_card", "loan", "mortgage"].includes(type)
    this.minimumPaymentFieldTarget.style.display = showMinPayment ? "" : "none"

    // Credit limit: credit_card only
    const showCreditLimit = type === "credit_card"
    this.creditLimitFieldTarget.style.display = showCreditLimit ? "" : "none"

    // Original balance: loan, mortgage
    const showOrigBalance = ["loan", "mortgage"].includes(type)
    this.originalBalanceFieldTarget.style.display = showOrigBalance ? "" : "none"
  }
}

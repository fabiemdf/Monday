class Claim < ApplicationRecord
  validates :claim_number, presence: true, uniqueness: true
  validates :client_name, presence: true
  validates :date_filed, presence: true
  validates :status, presence: true
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }

  STATUSES = %w[pending approved rejected in_progress].freeze

  validates :status, inclusion: { in: STATUSES }, allow_nil: true

  before_validation :set_default_status, on: :create

  private

  def set_default_status
    self.status ||= "pending"
  end
end

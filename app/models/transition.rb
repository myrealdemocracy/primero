class Transition
  include Syncable::PrimeroEmbeddedModel
  include PrimeroModel

  validate :validate_record

  property :type, String
  property :to_user_local, String
  property :to_user_remote, String
  property :to_user_agency, String
  property :to_user_local_status, String
  property :notes, String
  property :transitioned_by, String
  property :service, String
  property :is_remote, TrueClass
  property :type_of_export, String
  property :consent_overridden, TrueClass
  property :created_at, Date
  property :id

  TYPE_REFERRAL = "referral"
  TYPE_REASSIGN = "reassign"
  TYPE_TRANSFER = "transfer"

  TO_USER_LOCAL_STATUS_PENDING = "user_local_status_pending"
  TO_USER_LOCAL_STATUS_ACCEPTED = "user_local_status_accepted"
  TO_USER_LOCAL_STATUS_REJECTED = "user_local_status_rejected"

  def initialize *args
    super

    self.id ||= UUIDTools::UUID.random_create.to_s
  end

  def parent_record
    base_doc
  end

  private

  def validate_record
    #TODO
  end
end

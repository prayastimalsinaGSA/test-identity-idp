require 'rails_helper'

describe Idv::Steps::InPerson::AddressStep do
  let(:submitted_values) { {} }
  let(:pii_from_user) { flow.flow_session[:pii_from_user] }
  let(:params) { ActionController::Parameters.new({ in_person_address: submitted_values }) }
  let(:capture_secondary_id_enabled) { false }
  let(:enrollment) { InPersonEnrollment.new(capture_secondary_id_enabled:) }
  let(:user) { build(:user) }
  let(:service_provider) { create(:service_provider) }
  let(:controller) do
    instance_double(
      'controller',
      session: { sp: { issuer: service_provider.issuer } },
      params: params,
      current_user: user,
    )
  end

  let(:flow) do
    Idv::Flows::InPersonFlow.new(controller, {}, 'idv/in_person')
  end

  subject(:step) do
    Idv::Steps::InPerson::AddressStep.new(flow)
  end

  before(:each) do
    allow(step).to receive(:current_user).
      and_return(user)
    allow(user).to receive(:establishing_in_person_enrollment).
      and_return(enrollment)
  end

  describe '#call' do
    before do
      allow(IdentityConfig.store).to receive(:in_person_capture_secondary_id_enabled).
        and_return(false)
    end
    context 'with values submitted' do
      let(:address1) { '1 FAKE RD' }
      let(:address2) { 'APT 1B' }
      let(:city) { 'GREAT FALLS' }
      let(:zipcode) { '59010' }
      let(:state) { 'Montana' }
      let(:same_address_as_id) { false }
      let(:submitted_values) do
        {
          address1:,
          address2:,
          city:,
          zipcode:,
          state:,
          same_address_as_id:,
        }
      end

      before(:each) do
        Idv::InPerson::AddressForm::ATTRIBUTES.each do |attr|
          expect(flow.flow_session[:pii_from_user]).to_not have_key attr
        end

        step.call
      end

      it 'sets values in flow session' do
        expect(flow.flow_session[:pii_from_user]).to include(
          address1:,
          address2:,
          city:,
          zipcode:,
          state:,
          same_address_as_id:,
        )
      end

      context 'with secondary capture enabled' do
        let(:capture_secondary_id_enabled) { true }
        it 'excludes same_address_as_id from session' do
          expect(flow.flow_session[:pii_from_user]).not_to include(
            same_address_as_id:,
          )
        end

        it 'sets other values in flow session' do
          expect(flow.flow_session[:pii_from_user]).to include(
            address1:,
            address2:,
            city:,
            zipcode:,
            state:,
          )
        end
      end
    end
  end

  describe '#analytics_submitted_event' do
    it 'logs idv_in_person_proofing_address_submitted' do
      expect(step.analytics_submitted_event).to be(:idv_in_person_proofing_address_submitted)
    end

    context 'with secondary capture enabled' do
      let(:capture_secondary_id_enabled) { true }
      it 'logs idv_in_person_proofing_residential_address_submitted' do
        expect(step.analytics_submitted_event).to be(
          :idv_in_person_proofing_residential_address_submitted,
        )
      end
    end
  end

  describe '#extra_view_variables' do
    let(:address1) { '123 Fourth St' }
    let(:params) { ActionController::Parameters.new }

    context 'address1 is set' do
      it 'returns extra view variables' do
        pii_from_user[:address1] = address1

        expect(step.extra_view_variables).to include(
          pii: include(
            address1:,
          ),
          updating_address: true,
        )
      end
    end

    it 'returns capture enabled = false' do
      expect(step.extra_view_variables).to include(
        capture_secondary_id_enabled: false,
      )
    end

    context 'with secondary capture enabled' do
      let(:capture_secondary_id_enabled) { true }
      it 'returns capture enabled = true' do
        expect(step.extra_view_variables).to include(
          capture_secondary_id_enabled: true,
        )
      end
    end
  end
end

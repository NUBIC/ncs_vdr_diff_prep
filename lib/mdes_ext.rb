require 'ncs_navigator/mdes'

module NcsNavigator::Mdes
  # Ripped from ncs_mdes_warehouse.
  class TransmissionTable
    def wh_model_name(module_name=nil)
      name_text, numeric_suffix = name.scan(/^(.*?)([_\d]*)$/).first

      [
        module_name,
        [name_text.camelize, numeric_suffix].compact.join
      ].compact.join('::')
    end

    def wh_variables
      variables.reject { |v| v.name == 'transaction_type' }
    end

    def wh_keys
      @wh_keys ||=
        begin
          pks = variables.select { |v| v.type.name == 'primaryKeyType' }
          if !pks.empty?
            pks
          elsif name == 'study_center'
            variables.select { |v| v.name == 'sc_id' }
          elsif name == 'psu'
            variables.select { |v| v.name == 'psu_id' }
          else
            fail "Could not determine key to use for #{name} table"
          end
        end
    end

    def wh_manual_validations
      variables.collect do |v|
        v.wh_manual_validations
      end.flatten
    end
  end
end

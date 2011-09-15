module ActsAsMetadataHelper
  def metadata_type_datatype_names
    return MetadataType::DATATYPES.map { |key, value| [t("activerecord.attributes.metadata_type.datatypes.#{value}"), key] }
  end  
  
  def metadata_type_form_fields(f)
    res = ""
    f.object.metadata_types.each do |tag|
      type = MetadataType.type(tag)
      res += f.label(type.name)
      case type.datatype
        when "boolean"
          res += f.check_box(type.tag)
        when "text"
          res += f.text_area(type.tag)
        when "datetime"
          res += f.text_field(type.tag)
        when "date"
          res += f.text_field(type.tag)
        when "number"
          res += f.text_field(type.tag)
        when "string"
          res += f.text_field(type.tag)
      end
    end
    res.html_safe
  end

	def metadata_type_datatype_name(type)
    return t("activerecord.attributes.metadata_type.datatypes.#{MetadataType::DATATYPES[type.datatype.to_sym]}")
  end

	
  def metadata_type_mandatory_name(type)
    return t("activerecord.attributes.metadata_type.mandatory_values.#{type.mandatory}")
  end
end

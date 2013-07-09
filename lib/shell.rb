require 'libxml'
require 'logger'
require 'ncs_navigator/mdes'
require File.expand_path('../mdes_ext', __FILE__)

class Shell
  attr_reader :doc
  attr_reader :file
  attr_reader :logger
  attr_reader :mdes_version

  def initialize(file, mdes_version, logger)
    @file = file
    @doc = make_reader
    @mdes_version = mdes_version
    @logger = logger
  end

  def run
    logger.info "Operating on #{file == '-' ? '(stdin)' : file}"

    doc_read_ok = false
    mdes = NcsNavigator::Mdes::Specification.new(mdes_version)

    # For each transmission table in this MDES version, figure out its keys.
    keys = mdes.transmission_tables.each_with_object({}) do |tt, h|
      h[tt.name] = tt.wh_keys
    end

    # Skip to the transmission tables.
    while doc.name != 'ncs:transmission_tables'
      doc_read_ok = doc.read
    end

    # Is everything sane?
    if !doc_read_ok
      logger.fatal <<-END
      We ended up reading to EOF while trying to find ncs:transmission_tables.
      Aborting.
      END

      return
    end

    while doc.read
      node = doc.expand

      if node.element? && node.children? && node.children.any? { |c| !c.text? }
        ns = node.name + ":" + id_for(node, keys)

        yield node, ns
      end
    end
  end

  private

  def id_for(node, keys)
    name = node.name
    keys = keys[name]
    children = node.children

    keys.sort.map do |k|
      kv = children.detect { |c| c.name == k.name }

      if kv.nil? || kv.child.nil?
        'MISSING'
      else
        kv.child.inspect
      end
    end.join
  end

  def make_reader
    if file == '-'
      LibXML::XML::Reader.io($stdin)
    else
      LibXML::XML::Reader.file(file)
    end
  end
end

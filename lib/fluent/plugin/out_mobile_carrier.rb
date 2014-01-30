# mobile carrieroutput
class Fluent::MobileCarrierOutput < Fluent::Output
  Fluent::Plugin.register_output('mobile_carrier', self)

  config_param :config_yaml,   :string
  config_param :remove_prefix, :string, default: nil
  config_param :add_prefix,    :string, default: nil

  config_param :key_name,               :string
  config_param :unknown_carrier,        :string, default: 'UNKNOWN'
  config_param :out_key_mobile_carrier, :string, default: 'mobile_carrier'

  def initialize
    super
    require 'yaml'
  end

  def configure(conf)
    super
    config =  YAML.load_file(@config_yaml)
    raise 'invalid yaml' unless (config.is_a? Hash)
    @config = parse_config(config)

    if !@tag && !@remove_prefix && !@add_prefix
      fail Fluent::ConfigError, 'missing both of remove_prefix and add_prefix'
    end
    if @tag && (@remove_prefix || @add_prefix)
      fail Fluent::ConfigError, 'both of tag and remove_prefix/add_prefix must not be specified'
    end
    if @remove_prefix
      @removed_prefix_string = @remove_prefix + '.'
      @removed_length = @removed_prefix_string.length
    end
    @added_prefix_string = @add_prefix + '.' if @add_prefix
  end

  def tag_mangle(tag)
    if @tag
      @tag
    else
      if @remove_prefix &&
          ( (tag.start_with?(@removed_prefix_string) && tag.length > @removed_length) || tag == @remove_prefix)
        tag = tag[@removed_length..-1]
      end
      if @add_prefix
        tag = if tag && tag.length > 0
                @added_prefix_string + tag
              else
                @add_prefix
              end
      end
      tag
    end
  end

  def parse_config(raw_config)
    config = {}
    raw_config.each { |carrier, ip_address_list|
      config[carrier] = ip_address_list.map { |ip_address|
        TubeAddress.new(ip_address)
      }
    }
    config
  end

  def judge_mobile_carrier(ip_address, config)
    config.each { |carrier, ipaddr_list|
      if ipaddr_list.any? { |ipaddr| ipaddr.include? ip_address }
        return carrier
      end
    }
    @unknown_carrier
  end

  def emit(tag, es, chain)
    tag = tag_mangle(tag)
    es.each do |time, record|
      record.merge!(
        @out_key_mobile_carrier => judge_mobile_carrier(record[@key_name], @config)
      )
      Fluent::Engine.emit(tag, time, record)
    end
    chain.next
  end
end

# https://github.com/jordansissel/experiments/blob/master/ruby/ipaddr-is-slow/code.rb
class TubeAddress
  IPv4MASK = 0xFFFFFFFF # 255.255.255.255

  def initialize(addr)
    @address, cidr, _ = addr.split("/") + ["32"]

    @address_int = self.class.ip_to_num(@address)
    @cidr = cidr.to_i
    @base = @address_int & cidr_mask
  end

  def cidr_mask
    # Convert /24 to 0xffffff00, etc
    @cidr_mask ||= IPv4MASK ^ ((1 << (32 - @cidr)) - 1)
  end

  def include?(addr)
    return false if addr.nil?
    self.class.ip_to_num(addr) & @cidr_mask == @base
  end

  def self.ip_to_num(addr)
    return addr.split(".").reduce(0) { |s,c| s = (s << 8) + (c.to_i) }
  end

  def to_s
    return "#{@address}/#{@cidr}"
  end
end


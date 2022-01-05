# frozen_string_literal: true

module ActiveGraphExtensions
  module Node
    module Query
      module QueryProxyEagerLoading
        # Used to append auth scopes to query proxy eagerloading
        module ScopeEagerLoading
          def authorized_rel(path, var)
            rel_model = relationship_model(path)
            return {} if @opts.blank? || !(auth_scope = authorized_scope(rel_model, path))
            conf = { rels: [], chain: {} }
            proxy = auth_scope.call(var, "#{var}_rel", user: @opts[:user],
                                                       properties: properties_for(rel_model),
                                                       privileges: @opts[:privileges],
                                                       rel_length: path.last.rel_length)
            proxy_rel_parts(proxy.instance_variable_get(:@break_proxy) || proxy, conf)
            conf
          end

          def properties_for(rel_model)
            return [] unless @opts[:properties]
            @opts[:properties].select { |prop| prop.model.name == rel_model.name }.map(&:name)
          end

          def relationship_model(path)
            path[0..-2].inject(model) { |mod, rel| mod.send(rel.name).model }
          end

          def authorized_scope(rel_model, path)
            rel_model.scopes["authorized_#{path.last.association.name}".to_sym]
          end

          def proxy_rel_parts(auth_proxy, conf)
            return unless auth_proxy&.association
            rel_length = auth_proxy.instance_variable_get(:@rel_length)
            conf[:rels] << relationship_part(auth_proxy.association, auth_proxy.identity, rel_length)
            assign_config_chain(conf, auth_proxy, rel_length)
            proxy_rel_parts(auth_proxy.query_proxy, conf)
          end

          def assign_config_chain(conf, auth_proxy, rel_length)
            return unless (auth_chain = auth_proxy.instance_variable_get(:@chain))
            conf[:chain][[auth_proxy.identity, rel_length ? "#{auth_proxy.identity}_rel" : nil]] = auth_chain
          end
        end
      end
    end
  end
end

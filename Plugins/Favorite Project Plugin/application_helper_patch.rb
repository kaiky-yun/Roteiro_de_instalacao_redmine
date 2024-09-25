module RedmineFavoriteProjects
  module Patches
    module ApplicationHelperPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          alias_method :render_projects_for_jump_box_without_favorites, :render_projects_for_jump_box
          alias_method :render_projects_for_jump_box, :render_projects_for_jump_box_with_favorites
        end
      end

      module InstanceMethods
        def render_projects_for_jump_box_with_favorites(projects, selected = nil)
          favorite_projects_ids = FavoriteProject.where(user_id: User.current.id).pluck(:project_id)
          favorite_projects = Project.visible.where(id: favorite_projects_ids)

          return render_projects_for_jump_box_without_favorites(projects, selected) if projects.blank?

          jump_box = Redmine::ProjectJumpBox.new(User.current)
          bookmarked = jump_box.bookmarked_projects
          recents = jump_box.recently_used_projects
          jump = params[:jump].presence || current_menu_item
          s = (+'').html_safe
          build_project_link = lambda do |project, level = 0|
            padding = level * 16
            text = content_tag('span', project.name, style: "padding-left:#{padding}px")
            s << link_to(text, project_path(project, jump: jump), title: project.name, class: (project == @project ? 'selected' : nil))
          end

          [
            [favorite_projects, :label_favorite_projects, true],
            [bookmarked, :label_optgroup_bookmarks, true],
            [recents, :label_optgroup_recents, false],
            [projects, :label_project_all, true]
          ].each do |proj_group, label, is_tree|
            next if proj_group.blank?

            s << content_tag(:strong, l(label))
            is_tree ? project_tree(proj_group, &build_project_link) : proj_group.each(&build_project_link)
          end
          s
        end
      end
    end
  end
end

unless ApplicationHelper.included_modules.include?(RedmineFavoriteProjects::Patches::ApplicationHelperPatch)
  ApplicationHelper.send(:include, RedmineFavoriteProjects::Patches::ApplicationHelperPatch)
end

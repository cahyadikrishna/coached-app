module UiHelper
  BUTTON_BASE = "inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:size-4 [&_svg]:shrink-0"

  BUTTON_VARIANTS = {
    default: "bg-primary text-primary-foreground shadow hover:bg-primary/90",
    destructive: "bg-destructive text-destructive-foreground shadow-sm hover:bg-destructive/90",
    outline: "border border-input bg-background shadow-sm hover:bg-accent hover:text-accent-foreground",
    secondary: "bg-secondary text-secondary-foreground shadow-sm hover:bg-secondary/80",
    ghost: "hover:bg-accent hover:text-accent-foreground",
    link: "text-primary underline-offset-4 hover:underline"
  }.freeze

  BUTTON_SIZES = {
    default: "h-9 px-4 py-2",
    sm: "h-8 rounded-md px-3 text-xs",
    lg: "h-10 rounded-md px-8",
    icon: "h-9 w-9"
  }.freeze

  BADGE_BASE = "inline-flex items-center rounded-md border px-2.5 py-0.5 text-xs font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2"

  BADGE_VARIANTS = {
    default: "border-transparent bg-primary text-primary-foreground shadow hover:bg-primary/80",
    secondary: "border-transparent bg-secondary text-secondary-foreground hover:bg-secondary/80",
    destructive: "border-transparent bg-destructive text-destructive-foreground shadow hover:bg-destructive/80",
    outline: "text-foreground"
  }.freeze

  def ui_button(name = nil, variant: :default, size: :default, **options, &block)
    klass = [ BUTTON_BASE, BUTTON_VARIANTS.fetch(variant.to_sym, BUTTON_VARIANTS[:default]),
             BUTTON_SIZES.fetch(size.to_sym, BUTTON_SIZES[:default]), options.delete(:class) ].compact.join(" ")
    content = block ? capture(&block) : name

    if (href = options.delete(:href))
      link_to(href, class: klass, **options) { content }
    else
      options[:type] ||= "button"
      content_tag(:button, **options.merge(class: klass)) { content }
    end
  end

  def ui_badge(text = nil, variant: :default, **options, &block)
    klass = [ BADGE_BASE, BADGE_VARIANTS.fetch(variant.to_sym, BADGE_VARIANTS[:default]),
             options.delete(:class) ].compact.join(" ")
    content_tag(:span, **options.merge(class: klass)) { block ? capture(&block) : text }
  end

  def ui_card(**options, &block)
    klass = [ "rounded-xl border bg-card text-card-foreground shadow", options.delete(:class) ].compact.join(" ")
    content_tag(:div, **options.merge(class: klass), &block)
  end

  def ui_card_header(**options, &block)
    klass = [ "flex flex-col space-y-1.5 p-6", options.delete(:class) ].compact.join(" ")
    content_tag(:div, **options.merge(class: klass), &block)
  end

  def ui_card_title(text = nil, **options, &block)
    klass = [ "font-semibold leading-none tracking-tight", options.delete(:class) ].compact.join(" ")
    content_tag(:div, **options.merge(class: klass)) { block ? capture(&block) : text }
  end

  def ui_card_description(text = nil, **options, &block)
    klass = [ "text-sm text-muted-foreground", options.delete(:class) ].compact.join(" ")
    content_tag(:div, **options.merge(class: klass)) { block ? capture(&block) : text }
  end

  def ui_card_content(**options, &block)
    klass = [ "p-6 pt-0", options.delete(:class) ].compact.join(" ")
    content_tag(:div, **options.merge(class: klass), &block)
  end

  def ui_card_footer(**options, &block)
    klass = [ "flex items-center p-6 pt-0", options.delete(:class) ].compact.join(" ")
    content_tag(:div, **options.merge(class: klass), &block)
  end

  def ui_alert(variant: :default, **options, &block)
    variants = {
      default: "bg-background text-foreground",
      destructive: "border-destructive/50 text-destructive dark:border-destructive [&>svg]:text-destructive"
    }
    klass = [ "relative w-full rounded-lg border px-4 py-3 text-sm [&>svg+div]:translate-y-[-3px] [&>svg]:absolute [&>svg]:left-4 [&>svg]:top-4 [&>svg]:text-foreground [&>svg~*]:pl-7",
             variants.fetch(variant.to_sym, variants[:default]), options.delete(:class) ].compact.join(" ")
    content_tag(:div, role: "alert", **options.merge(class: klass), &block)
  end

  def ui_alert_title(text = nil, **options, &block)
    klass = [ "mb-1 font-medium leading-none tracking-tight", options.delete(:class) ].compact.join(" ")
    content_tag(:h5, **options.merge(class: klass)) { block ? capture(&block) : text }
  end

  def ui_alert_description(text = nil, **options, &block)
    klass = [ "text-sm [&_p]:leading-relaxed", options.delete(:class) ].compact.join(" ")
    content_tag(:div, **options.merge(class: klass)) { block ? capture(&block) : text }
  end

  def ui_table(**options, &block)
    klass = [ "w-full caption-bottom text-sm", options.delete(:class) ].compact.join(" ")
    content_tag(:table, **options.merge(class: klass), &block)
  end

  def ui_table_header(**options, &block)
    klass = [ "[&_tr]:border-b", options.delete(:class) ].compact.join(" ")
    content_tag(:thead, **options.merge(class: klass), &block)
  end

  def ui_table_body(**options, &block)
    klass = [ "[&_tr:last-child]:border-0", options.delete(:class) ].compact.join(" ")
    content_tag(:tbody, **options.merge(class: klass), &block)
  end

  def ui_table_row(**options, &block)
    klass = [ "border-b transition-colors hover:bg-muted/50 data-[state=selected]:bg-muted", options.delete(:class) ].compact.join(" ")
    content_tag(:tr, **options.merge(class: klass), &block)
  end

  def ui_table_head(text = nil, **options, &block)
    klass = [ "h-10 px-2 text-left align-middle font-medium text-muted-foreground [&:has([role=checkbox])]:pr-0", options.delete(:class) ].compact.join(" ")
    content_tag(:th, **options.merge(class: klass)) { block ? capture(&block) : text }
  end

  def ui_table_cell(text = nil, **options, &block)
    klass = [ "p-2 align-middle [&:has([role=checkbox])]:pr-0", options.delete(:class) ].compact.join(" ")
    content_tag(:td, **options.merge(class: klass)) { block ? capture(&block) : text }
  end

  def ui_avatar(user: nil, src: nil, alt: nil, **options, &block)
    klass = [ "relative flex h-10 w-10 shrink-0 overflow-hidden rounded-full", options.delete(:class) ].compact.join(" ")
    src ||= user&.avatar_url
    alt ||= user&.name

    content_tag(:span, **options.merge(class: klass)) do
      if src.present?
        image_tag(src, alt: alt, class: "aspect-square h-full w-full object-cover")
      else
        ui_avatar_fallback(user&.name || alt)
      end
    end
  end

  def ui_avatar_fallback(name = nil, **options)
    klass = [ "flex h-full w-full items-center justify-center rounded-full bg-muted text-sm", options.delete(:class) ].compact.join(" ")
    content_tag(:span, **options.merge(class: klass)) { avatar_initials(name) }
  end

  private

  def avatar_initials(name)
    return "?" if name.blank?
    name.split.map(&:first).first(2).join.upcase
  end
end

module ApplicationHelper
  def default_meta_tags
    {
      site: Settings.app_name,
      reverse: true,
      title: nil,
      description: Settings.page_description,
      keywords: Settings.page_keywords,
      canonical: request.base_url,
      og: {
        title: :title,
        type: 'website',
        url: request.base_url,
        # image: image_url(Settings.site.meta.ogp.image_path),
        site_name: Settings.app_name,
        description: :description,
        locale: 'ja_JP'
      },
      twitter: {
        card: 'summary',
        site: '@White_mak4026'
      }
    }
  end
end

class Technology < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged
  include GenerateCsv
  acts_as_taggable
  acts_as_taggable_on :base_techs
  audited

  belongs_to :adoption_level
  belongs_to :readiness_level
  belongs_to :governance
  has_and_belongs_to_many :functions
  has_and_belongs_to_many :categories
  has_many :relationships

  before_destroy :remove_relationships

  #has_many :subjects, class_name: 'Relationship', foreign_key: 'subject_id'
  #has_many :objects, class_name: 'Relationship', foreign_key: 'object_id'
  #
  def depends_on
    technology_list = []
    Relationship.where(:subj => self,:predicate => 'depends_on').each {|rel| technology_list << rel.obj}
    return technology_list
  end

  def is_depended_on_by
    technology_list = []
    Relationship.where(:obj => self,:predicate => 'depends_on').each {|rel| technology_list << rel.subj}
    return technology_list
  end

  def self.dump_to_json(technologies=all)
    tech_array = []
    technologies.each do |technology|
      tech = {}
      tech['id'] = technology.slug
      tech['name'] = technology.name
      tech['description'] = technology.description
      tech['url'] = technology.url
      tech['adoption_level'] = technology.adoption_level.name
      tech['readiness_level'] = technology.readiness_level.name
      tech['governance'] = technology.governance.name
      tech['categories'] = technology.categories.collect { |category| category.name }
      tech['functions'] = technology.functions.collect { |function| function.name }
      tech['base_technologies'] = technology.base_techs.collect { |base_tech| base_tech.name }
      tech['tags'] = technology.tags.collect { |tag| tag.name }
      tech['is_depended_on_by'] = technology.is_depended_on_by.collect { |child_tech| child_tech.slug }
      tech['depends_on'] = technology.depends_on.collect { |parent_tech| parent_tech.slug }
      tech_array << tech
    end
    tech_array.to_json
  end

  def self.dump_to_csv(technologies=all)
    CSV.generate(headers: true) do |csv|
      csv << ['id','name','description','url','adoption_level','readiness_level','governance','categories','functions','base_technologies','tags','is_depended_on_by','depends_on']
      technologies.each do |technology|
        row = []
        row << technology.slug
        row << technology.name
        row << technology.description
        row << technology.url
        row << technology.adoption_level.name
        row << technology.readiness_level.name
        row << technology.governance.name
        row << technology.categories.collect { |category| category.name }.join('|')
        row << technology.functions.collect { |function| function.name }.join('|')
        row << technology.base_techs.collect { |base_tech| base_tech.name }.join('|')
        row << technology.tags.collect { |tag| tag.name }.join('|')
        row << technology.is_depended_on_by.collect { |tech| tech.slug }.join('|')
        row << technology.depends_on.collect { |tech| tech.slug }.join('|')
        csv << row
      end
    end
  end

  private
    def remove_relationships
      Relationship.destroy_by(subj_id: self.id)
      Relationship.destroy_by(obj_id: self.id)
    end
end

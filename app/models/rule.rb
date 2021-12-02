# frozen_string_literal: true

# rules for mail services
class Rule < ApplicationRecord
  belongs_to :mail_service_rule

  enum rule_field: {
    weight_in_gm: 'weight in GM',
    max_weight_in_gm: 'max weight in GM',
    max_width_in_mm: 'max width in MM',
    max_length_in_mm: 'max length in MM',
    max_height_in_mm: 'max height in MM',
    total_width_in_mm: 'total width in MM',
    total_length_in_mm: 'total length in MM',
    total_height_in_mm: 'total height in MM',
    any_dimension_in_mm: 'any dimension in MM',
    total_volume_in_mm3: 'total volume in MM³',
    item_volume_in_mm3: 'item volume in MM³',
    formula_is_true: 'formula is true (Advanced)', ########## 1
    formula_is_not_true: 'formula is not true (Advanced)', ########## 1
    total_item_value_in_pence: 'total item value in pence',
    total_postage_value_in_pence: 'total postage value in pence',
    next_day_of_the_week_from_order_placed: 'next day of the week from order placed',
    day_of_the_week_order_placed: 'day of the week order placed',
    hour_of_the_day: 'hour of the day',
    minute_of_the_day: 'minute of the day',
    large_letter_compatible_products: 'large letter compatible products',
    postcode: 'postcode',
    address_line_one: 'address line 1',
    address_line_two: 'address line 2',
    town: 'town',
    county: 'county',
    country: 'country',
    products_option_equals: 'products option equals', ###### 2
    products_option_does_not_equals: 'products option does not equals', ###### 2
    product_option_contains: 'product option contains', ###### 2
    product_option_does_not_contains: 'product option does not contains', ###### 2
    multipack_product_option_equals: 'multipack product option equals', ###### 2
    multipack_product_option_does_not_equals: 'multipack product option does not equals', ###### 2
    multipack_product_option_contains: 'multipack product option contains', ###### 2
    multipack_product_option_does_not_contains: 'multipack product option does not contains', ###### 2
    total_number_products_ordered: 'total number products ordered',
    maximum_number_of_individual_products_ordered: 'maximum number of individual products ordered',
    minimum_number_of_individual_products_ordered: 'minimum number of individual products ordered',
    total_number_of_distinct_products_on_an_order: 'total number of distinct products on an order',
    customer_name: 'customer name',
    customer_type: 'customer type',
    payment_terms: 'payment terms',
    shipping_service_name: 'shipping service name',
    product_supplier: 'product supplier',
    product_sku: 'product sku',
    any_product_sku: 'any product sku',
    range_sku: 'range sku',
    all_items_on_order_are_in_multipacks: 'all items on order are in multipacks',
    all_items_on_order_are_standard_products: 'all items on order are standard products',
    order_contains_mix_of_multipack_and_standard_products: 'order contains mix of multipack and standard products',
    multipack_weight_in_gm: 'multipack weight in GM',
    multipack_max_width_in_mm: 'multipack max width in MM',
    multipack_max_length_in_MM: 'multipack max length in MM',
    multipack_height_in_mm: 'multipack height in MM',
    multipack_total_width_in_mm: 'multipack total width in MM',
    multipack_total_length_in_mm: 'multipack total length in MM',
    multipack_total_height_in_mm: 'multipack total height in MM',
    any_multipack_dimension_in_mm: 'any multipack dimension in MM',
    delivery_mobile_set: 'delivery mobile set',
    delivery_telephone_set: 'delivery telephone set',
    customer_email_set: 'customer email set',
    warehouse_any_product: 'warehouse any product', ##### 3
    warehouse_all_product: 'warehouse all product', ##### 3
    order_is_split_across_multiple_warehouses: 'order is split across multiple warehouses',
    any_product_on_order_is_dropshiped_by: 'any product on order is dropshiped by', ##### 4
    all_product_on_order_is_dropshiped_by: 'all product on order is dropshiped by', ##### 4
    any_product_has_additional_labels: 'any product has additional labels',
    all_product_has_additional_labels: 'all product has additional labels',
    any_product_line_gross: 'any product line gross (Pence)',
    any_product_line_gross_before_discount: 'any product line gross before discount (Pence)',
    any_single_product_line_gross: 'any single product line gross (Pence)',
    any_single_product_line_gross_before_discount: 'any single product line gross before discount (Pence)',
    any_multipack_product_line_gross: 'any multipack product line gross (Pence)',
    any_multipack_product_line_gross_before_discount: 'any multipack product line gross before discount (Pence)',
    any_product_item_gross: 'any product item gross (Pence)',
    any_product_item_gross_before_discount: 'any product item gross before discount (Pence)',
    any_single_product_item_gross: 'any single product item gross (Pence)',
    any_single_product_item_gross_before_discount: 'any single product item gross before discount (Pence)',
    any_multipack_product_item_gross: 'any multipack product item gross (Pence)',
    any_multipack_product_item_gross_before_discount: 'any multipack product item gross before discount (Pence)',
    total_gross_of_items_on_the_order: 'total gross of items on the order (Pence)',
    total_gross_of_items_on_the_order_before_discount: 'total gross of items on the order before discount (Pence)',
    total_vat_of_items_on_the_order: 'total Vat of items on the order (Pence)',
    total_net_of_items_on_the_order: 'total Net of items on the order (Pence)'
  }, _prefix: true

  enum rule_operator: {
    greater_then: '>',
    less_then: '<',
    equals: '=',
    greater_then_equal: '>=',
    less_then_equal: '<=',
    between: 'between',
    not_between: 'not between',
    contains: 'contains',
    does_not_contain: 'does not contain',
    start_with: 'start with',
    end_with: 'end_with'
  }, _prefix: true

  enum rule_operator_product_options: {
    absorbency: 'absorbency',
    accessory: 'accessory',
    active_ingredients: 'Active Ingredients',
    age_group: 'Age Group',
    age_level: 'Age Level',
    allergens: 'allergens',
    amount: 'amount',
    appliance_capabilities: 'Appliance Capabilities',
    appliance_uses: 'Appliance Uses',
    application: 'Application',
    application_method: 'Application Method',
    activity: 'Activity',
    area_of_use: 'Area of Use',
    assembly_required: 'Assembly Required',
    base_material: 'Base Material',
    battery_included: 'Battery Included',
    body_area: 'Body Area',
    brand: 'Brand',
    bristle_material: 'Bristle Material',
    bundle_description: 'Bundle Description',
    bundle_listing: 'Bundle Listing',
    cable_length: 'Cable Length',
    cable_size: 'Cable Size',
    capacity: 'Capacity',
    category: 'Category',
    certification_required: 'Certification Required',
    character: 'Character',
    character_family: 'Character Family',
    choose: 'Choose',
    choose_item: 'Choose Item',
    choose_package: 'Choose Package',
    choose_paint: 'Choose Paint;',
    choose_set: 'Choose Set;',
    choose_size: 'Choose Size',
    choose_weight: 'Choose Weight',
    choose_your_package: 'Choose Your Package',
    clothing_type: 'Clothing Type',
    cocoa_content: 'Cocoa Content',
    color: 'Color',
    colour: 'Colour',
    common_name: 'Common Name',
    compatibility: 'Compatibility',
    compatible_brand: 'Compatible Brand',
    compatible_model: 'Compatible Model',
    compatible_plant_type: 'Compatible Plant Type',
    container_size: 'Container Size',
    control_method: 'Control Method',
    control_style: 'Control Style',
    cord_type: 'Cord Type',
    count: 'Count',
    country_region_of_manufacture: 'Country/Region of Manufacture',
    custom_bundle: 'Custom Bundle',
    dehumidification_method: 'Dehumidification Method',
    department: 'Department',
    depth: 'Depth',
    design: 'Design',
    diameter: 'Diameter',
    dilution: 'Dilution',
    dimensions: 'Dimensions',
    dog_size: 'Dog Size',
    energy_per_100_g_m_l: 'Energy per 100 g/mL',
    expiration_date: 'Expiration Date',
    expiry_date: 'Expiry Date',
    fan_style: 'Fan Style',
    featured_refinements: 'Featured Refinements',
    features: 'Features',
    finger_toe: 'Finger/Toe',
    finish: 'Finish',
    firelighters: 'Firelighters',
    flavour: 'Flavour',
    food_aisle: 'Food Aisle',
    food_specifications: 'Food Specifications',
    for: 'For',
    form: 'Form',
    formulation: 'Formulation',
    fragrance: 'Fragrance',
    fragrance_name: 'Fragrance Name',
    frame_colour: 'Frame Colour',
    fuel_type: 'Fuel Type',
    function: 'Function',
    further_options: 'Further Options',
    gender: 'Gender',
    grill_size: 'Grill Size',
    hair_type: 'Hair Type',
    handle_material: 'Handle Material',
    hanger_size: 'Hanger Size',
    hazardous_characteristics: 'Hazardous Characteristics',
    head_material: 'Head Material',
    heat_resistance: 'Heat Resistance',
    heat_time: 'Heat Time',
    heating_system: 'Heating System',
    height: 'Height',
    housing_material: 'Housing Material',
    how_many_litres: 'How many Litres',
    how_many: 'How Many?',
    included_accessories: 'Included Accessories',
    indoor_outdoor: 'Indoor/Outdoor',
    ingredient: 'Ingredient',
    ingredients: 'Ingredients',
    installation_area: 'Installation Area',
    item: 'Item',
    item_condition: 'Item Condition',
    item_depth: 'Item Depth',
    item_diameter: 'Item Diameter',
    item_height: 'Item Height',
    item_length: 'Item Length',
    item_size: 'Item Size',
    item_type: 'Item Type',
    item_weight: 'Item Weight',
    item_width: 'Item Width',
    kit_type: 'Kit Type',
    labels_amp_certifications: 'Labels &amp; Certifications',
    lens_material: 'Lens Material',
    life_stage: 'Life Stage',
    lighting_technology: 'Lighting Technology',
    litres: 'Litres;',
    location: 'Location',
    main_colour: 'Main Colour',
    main_ingredient: 'Main Ingredient',
    main_ingredients: 'Main Ingredients',
    main_purpose: 'Main Purpose',
    making_method: 'Making Method',
    manufacturer: 'Manufacturer',
    manufacturer_colour: 'Manufacturer Colour',
    manufacturer_part_number: 'Manufacturer Part Number',
    manufacturer_warranty: 'Manufacturer Warranty',
    material: 'Material',
    material_basis: 'Material Basis',
    model: 'Model',
    modified_item: 'Modified Item',
    motion: 'Motion',
    mounting: 'Mounting',
    mounting_location: 'Mounting Location',
    mounting_style: 'Mounting Style',
    mounting_type: 'Mounting Type',
    mpn: 'MPN',
    no_of_bottles: 'No of bottles',
    no_of_trays: 'No of trays',
    no_of_airer: 'No. of Airer',
    no_of_bait_block: 'No. of Bait Block',
    no_of_blades: 'No. of Blades',
    no_of_blocks: 'No. of Blocks',
    no_of_bottle: 'No. of Bottle',
    no_of_pack: 'No. of Pack',
    no_of_tub: 'No. of Tub;',
    no_of_bags: 'No.of Bags',
    no_of_bait_blocks: 'No.of Bait Blocks',
    no_of_box: 'No.of Box',
    no_of_boxes: 'No.of Boxes',
    no_of_cubes: 'No.of Cubes',
    no_of_cups: 'No.of Cups',
    no_of_firelogs: 'No.of Firelogs',
    no_of_hanging_units: 'No.of Hanging Units',
    no_of_item: 'No.of Item',
    no_of_items: 'No.of Items',
    no_of_moisture_trap: 'No.of Moisture Trap',
    no_of_packs: 'No.of Packs',
    no_of_pairs: 'No.of Pairs',
    no_of_pants: 'No.of Pants',
    no_of_rolls: 'No.of Rolls',
    no_of_sachet: 'No.of Sachet',
    no_of_sachets: 'No.of Sachets',
    no_of_solution_bottle: 'No.of Solution Bottle',
    no_of_sponge: 'No.of Sponge',
    no_of_tin: 'No.of Tin',
    no_of_tins: 'No.of Tins',
    no_of_traps: 'No.of Traps',
    non_domestic_product: 'Non-Domestic Product',
    number_in_pack: 'Number in Pack',
    number_of_batteries: 'Number of Batteries',
    number_of_blades: 'Number of Blades',
    number_of_bottles: 'Number of bottles',
    number_of_burners: 'Number of Burners',
    number_of_firelighters: 'Number of Firelighters',
    number_of_holes: 'Number of Holes',
    number_of_item: 'Number of Item',
    number_of_items: 'Number of Items',
    number_of_items_in_set: 'Number of Items in Set',
    number_of_ply: 'Number of Ply',
    number_of_pods: 'Number of Pods',
    number_of_rack_tiers: 'Number Of Rack Tiers',
    number_of_racks: 'Number of Racks',
    number_of_rolls: 'Number of Rolls',
    number_of_servings: 'Number of Servings',
    number_of_sheets: 'Number of Sheets',
    number_of_waste_bin: 'Number of Waste Bin',
    occasion: 'Occasion',
    options: 'Options',
    organic: 'Organic',
    original_reproduction: 'Original/Reproduction',
    pack: 'Pack',
    pack_include: 'Pack include',
    pack_of: 'Pack of',
    pack_size: 'Pack Size',
    packaging: 'Packaging',
    packs: 'Packs',
    paint_volume: 'Paint Volume',
    pasteurisation: 'Pasteurisation',
    pattern: 'Pattern',
    period_after_opening_pao: 'Period After Opening (PAO)',
    personalised: 'Personalised',
    pest_type: 'Pest Type',
    pest_weed_type: 'Pest/Weed Type',
    p_h_value: 'pH Value',
    plant_type: 'Plant Type',
    play_equipment_type: 'Play Equipment Type',
    power: 'Power',
    power_source: 'Power Source',
    prevention: 'Prevention',
    product: 'Product',
    product_form: 'Product Form',
    product_line: 'Product Line',
    product_name: 'Product Name',
    product_type: 'Product Type',
    protected_certification: 'Protected Certification',
    protection_properties: 'Protection Properties',
    purpose: 'Purpose',
    qty: 'Qty',
    quantity: 'Quantity,',
    recommended_environment: 'Recommended Environment',
    regional_cuisine: 'Regional Cuisine',
    release_speed: 'Release Speed',
    roast: 'Roast',
    room: 'Room',
    salt_content: 'Salt Content',
    scent: 'Scent',
    season_of_interest: 'Season of Interest',
    select: 'Select',
    select_300_g_packs: 'Select 300g Packs',
    select_basket: 'Select Basket',
    select_chopping_board: 'Select Chopping Board',
    select_color: 'Select Color;',
    select_led: 'Select LED',
    select_object: 'Select Object',
    select_pack: 'Select Pack',
    select_scent: 'Select Scent',
    select_size: 'Select Size',
    select_stainer: 'Select Stainer',
    select_weight: 'Select Weight',
    set: 'Set',
    set_includes: 'Set Includes',
    set_of_jar: 'Set of Jar',
    shade: 'Shade',
    shape: 'Shape',
    sheen: 'Sheen',
    size: 'Size',
    size_type: 'Size Type',
    sizes: 'Sizes',
    skin_type: 'Skin Type',
    smart_home_compatibility: 'Smart Home Compatibility',
    smart_home_protocol: 'Smart Home Protocol',
    steam_time: 'Steam Time',
    style: 'Style',
    styling_effect: 'Styling Effect',
    subtype: 'Subtype',
    sub_type: 'Sub-Type',
    suitable_for: 'Suitable For',
    sun_protection_factor_spf: 'Sun Protection Factor (SPF)',
    surface_coating: 'Surface Coating',
    surface_appliance: 'Surface/Appliance',
    tank_capacity: 'Tank Capacity',
    target_area: 'Target Area',
    test: 'test',
    theme: 'Theme',
    tile_shape: 'Tile Shape',
    time_control: 'Time Control',
    transparency: 'Transparency',
    tv_film_character: 'TV/ Film Character',
    type: 'Type',
    type_of_cleaner: 'Type of Cleaner',
    type_of_oven: 'Type of Oven',
    unit_quantity: 'Unit Quantity',
    unit_type: 'Unit Type',
    use: 'Use',
    uva_protection: 'UVA Protection',
    vegetable_oil_content: 'Vegetable Oil Content',
    vendor: 'Vendor',
    voltage: 'Voltage',
    volume: 'Volume',
    weed_type: 'Weed Type',
    weed_pest_control_method: 'Weed/ Pest Control Method',
    weight: 'Weight',
    width: 'Width'
  }, _prefix: true

  enum rule_operator_warehouse: {
    fulfilled_by_amazon: 'Fulfilled by amazon',
    main_warehouse: 'Main warehouse'
  }, _prefix: true

  enum rule_operator_dropshipped: {
    stax: 'Stax',
    costco: 'Costco',
    clearance_king: 'Clearance King',
    primark: 'Primark',
    esg: 'ESG',
    swl: 'SWL',
    best_bargain: 'BestBargain',
    shonn_brothers: 'shonn brothers',
    wham: 'Wham',
    costoc_sale: 'costoc sale',
    makro: 'Makro',
    y_amp_y: 'Y & Y',
    decco: 'Decco',
    makeup: 'Makeup',
    otl: 'OTL',
    tiger_tim: 'Tiger Tim',
    barrettine: 'Barrettine',
    bartoline: 'Bartoline',
    bird_brand: 'Bird Brand',
    bio_bean_limited: 'Bio Bean Limited',
    rayburn: 'Rayburn',
    evergreen: 'Evergreen',
    growth_technology_ltd: 'Growth Technology Ltd',
    growth_tecnology: 'Growth Tecnology',
    white_horse_energy: 'White Horse Energy',
    iceland: 'Iceland',
    home_pack_ltd: 'Home Pack LTD',
    home_base: 'HomeBase',
    the_vacuum_pouch_company: 'The Vacuum Pouch Company',
    w_e_textiles_ltd: 'W.E TEXTILES LTD',
    hs_fuels_ltd: 'HS Fuels Ltd',
    cpl: 'CPL'
  }, _prefix: true
end

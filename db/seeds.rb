# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
Recipe.create([
  {
    title: "Fresh Ham With Maple-Balsamic Glaze",
    author: "Sam Sifton",
    prep_time: "3 1/2 to 4 hours",
    intro: "Think beyond pink. Here is a recipe for a fresh ham — uncured, unsmoked, straight from the butcher — roasted slowly in the oven beneath a shower of salt and pepper, glazed with maple syrup and balsamic vinegar, and finished with a mixture of toasted pecans and candied ginger. It makes for a holiday centerpiece of some distinction, and marvelous sandwiches afterward. Those with access to good pork, free-ranging and fed well, with lots of fat, do not have to brine the meat before cooking. But if you’re picking up a supermarket ham, it is a good bet to do so.",
    ingredients: [
      "1 10- to 12-pound butt or shank portion fresh ham, skin on",
      "4 teaspoons kosher salt",
      "4 teaspoons ground black pepper",
      "1 cup maple syrup",
      "1/2 cup balsamic vinegar",
      "1 teaspoon ground cinnamon",
      "1/2 cup pecans, toasted",
      "1/2 cup candied ginger"
    ],
    instructions: [
      "Heat oven to 450 degrees. Using a sharp knife, score entire surface of ham in a diamond pattern, cutting down just through the skin to the flesh underneath. (If you are cutting to the right depth, the skin will spread apart a bit as you cut.) Rub outside of ham all over with salt and pepper, pressing it into crosshatch spaces between the skin. Put roast on a rack in a large roasting pan and place in oven.",
      "After 20 minutes, reduce oven to 300 degrees. In a small bowl, whisk together maple syrup, balsamic vinegar and cinnamon. Baste ham hourly with mixture, as well as with fat from the bottom of the pan, roasting until the very center of the ham reaches an internal temperature of 145 degrees, 2 1/2 to 3 hours total cooking time. (Begin checking at 2 hours, inserting a meat thermometer into the absolute center of the roast.)",
      "Put the toasted pecans and candied ginger into a food processor and pulse lightly until crumbled and well combined.",
      "When ham is done, remove it from roasting pan, shower with pecan-ginger mixture and cover it loosely with foil. Allow the meat to rest for 20 to 30 minutes. (Its internal temperature will rise to 150 or more as it rests.)",
      "Tip roasting pan to the side so you can spoon off all the fat from the pan juices, then place pan on stove over medium-high heat. Scrape the bottom of pan to free any browned bits, skim any film off surface and season liquid as needed with salt and pepper. Pour into a gravy boat.",
      "Carve ham into thick slices, drizzle with pan sauce and serve, passing remaining sauce on the side."
    ],
    pic_url: "http://graphics8.nytimes.com/images/2014/04/16/dining/16EASTER_SPAN-recipe/16EASTER_SPAN-recipe-articleLarge-v3.jpg",
    pic_credit: "Andrew Scrivani for The New York Times",
    url: "http://cooking.nytimes.com/recipes/1016257-fresh-ham-with-maple-balsamic-glaze"
  }, {
    title: "James Beard’s Boston Baked Beans",
    author: "Amanda Hesser",
    intro: "The trick to good baked beans is cooking them very slowly with indirect heat. This recipe calls for baking them in a tightly sealed casserole in an oven barely hot enough to toast bread. As the hours pass, the beans drink up a broth flavored with brown sugar (or molasses), mustard and pepper. The gentle cooking prevents the beans from breaking up and becoming mushy. By the time they're done, the pork is falling off its bones and the beans are the classic rusty brown. Be sure to season them amply with salt so the sweetness has a sturdy counterpart.<br/>Beard's recipe calls for dark brown sugar. The alternative is to use molasses, which will render a final flavor and color more familiar to canned-bean devotees. The recipe itself requires no great cooking skills — if you can peel an onion and boil water, you're all set — but it will easily take up an afternoon. Plan it for a day when you're at home.",
    ingredients: [
      "2 cups of white pea beans (navy beans)",
      "1 scant teaspoon salt, plus more to taste",
      "1 medium onion, peeled",
      "4 pork spareribs, or 8 baby-back ribs",
      "1/3 cup dark brown sugar or molasses",
      "2 teaspoons dry mustard",
      "1 teaspoon ground black pepper"
    ],
    instructions: [
      "In a large bowl, soak the beans in 2 quarts of water for 6 hours. Drain the beans and put them in a large pot. Add the salt and enough cool water to cover 2 inches above the beans. Bring to a boil, then lower the heat and simmer gently, stirring occasionally, until the beans are just barely tender, 30 to 40 minutes. Drain well.",
      "Bring another pot of water to a boil. Preheat the oven to 250 degrees. In the bottom of a large casserole with a tight-fitting lid, place the peeled onion -- yes, whole -- and spareribs (or baby-back ribs). Spread the beans on top. In a small bowl, mix together the brown sugar (or molasses), mustard and black pepper and add this to the beans and pork. Pour in just enough boiling water to cover the beans, put the lid on and bake, occasionally adding more boiling water to keep the beans covered, until they are tender but not falling apart, 4 to 5 hours.",
      "Remove the casserole from the oven. Season the beans with salt. Pull the meat from the ribs. Discard the bones and excess fat and stir the meat back into the beans. With the lid off, return the casserole to the oven and let the beans finish cooking, uncovered and without additional water, until the sauce has thickened and is nicely caramelized on top, about 45 minutes more."
    ],
    pic_url: "http://graphics8.nytimes.com/images/2014/05/30/dining/Baked-Beans/Baked-Beans-articleLarge.jpg",
    pic_credit: "Tony Cenicola/The New York Times. Food Stylist: Jill Santopietro.",
    url: "http://cooking.nytimes.com/recipes/11877-james-beards-boston-baked-beans"
  }
])

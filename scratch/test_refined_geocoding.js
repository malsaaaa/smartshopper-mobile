const https = require('https');

const excludeWords = new Set([
  'taman', 'jalan', 'jln', 'lorong', 'desa', 'persiaran', 'lebuh', 'lebuhraya',
  'malaysia', 'melaka', 'malacca', 'selangor', 'johor', 'penang', 'perak', 
  'kedah', 'pahang', 'terengganu', 'kelantan', 'perlis', 'sabah', 'sarawak',
  'kuala', 'lumpur', 'putrajaya', 'labuan', 'negeri', 'sembilan', 'bandar',
  'utama', 'jaya', 'permai', 'indah', 'sentral', 'center', 'centre', 'plaza',
  'mall', 'hypermarket', 'supermarket', 'mart', 'wholesale', 'store', 'outlet',
  'kampung', 'kg', 'flat', 'apartment', 'condo', 'residence', 'residences',
  'block', 'blok', 'no', 'lot', 'tingkat', 'level', 'floor', 'jalan-jalan',
  'road', 'street', 'avenue', 'boulevard', 'lane'
]);

function reverseGeocode(lat, lon) {
  return new Promise((resolve, reject) => {
    const apiKey = 'AIzaSyClkMxhgs8P4GFqc5VkN4ylpXoDq7Ero-g';
    const url = `https://maps.googleapis.com/maps/api/geocode/json?latlng=${lat},${lon}&key=${apiKey}`;
    https.get(url, (res) => {
      let data = '';
      res.on('data', (c) => data += c);
      res.on('end', () => resolve(JSON.parse(data)));
    }).on('error', (e) => reject(e));
  });
}

function geocodeAddress(address) {
  return new Promise((resolve, reject) => {
    const query = encodeURIComponent(address);
    const apiKey = 'AIzaSyClkMxhgs8P4GFqc5VkN4ylpXoDq7Ero-g';
    const url = `https://maps.googleapis.com/maps/api/geocode/json?address=${query}&key=${apiKey}`;
    https.get(url, (res) => {
      let data = '';
      res.on('data', (c) => data += c);
      res.on('end', () => resolve(JSON.parse(data)));
    }).on('error', (e) => reject(e));
  });
}

function cleanComponentName(name) {
  let cleaned = name;
  const prefixes = [
    /^taman\s+desa\s+/i,
    /^taman\s+iks\s+/i,
    /^taman\s+/i,
    /^jalan\s+/i,
    /^lorong\s+/i,
    /^persiaran\s+/i,
    /^bandar\s+/i
  ];
  for (const pattern of prefixes) {
    cleaned = cleaned.replace(pattern, '');
  }
  return cleaned.trim();
}

async function run() {
  const points = [
    { name: 'Jasin (near Jasin Bestari)', lat: 2.2801, lon: 102.3911, brand: 'Mydin' },
    { name: 'Duyong (near Lotus\'s Duyong)', lat: 2.2044, lon: 102.3011, brand: 'Lotus\'s' }
  ];

  for (const pt of points) {
    console.log(`\n======================================================`);
    console.log(`Processing: ${pt.name} for brand: ${pt.brand}`);
    console.log(`======================================================`);
    
    const revData = await reverseGeocode(pt.lat, pt.lon);
    if (revData.status !== 'OK' || !revData.results || revData.results.length === 0) {
      console.log('Reverse geocoding failed');
      continue;
    }

    const components = revData.results[0].address_components;
    let localKeywords = [];
    
    const targetTypes = [
      'neighborhood',
      'sublocality_level_1',
      'sublocality',
      'locality',
      'administrative_area_level_2'
    ];

    for (const type of targetTypes) {
      for (const comp of components) {
        if (comp.types.includes(type)) {
          const name = comp.long_name;
          const cleanedName = cleanComponentName(name);
          
          // 1. Add full cleaned name if not excluded
          if (cleanedName.length > 2 && !excludeWords.has(cleanedName.toLowerCase()) && !localKeywords.includes(cleanedName)) {
            localKeywords.push(cleanedName);
          }
          
          // 2. Add individual split words if not excluded
          const words = cleanedName.toLowerCase().split(/[^a-zA-Z]/);
          for (const w of words) {
            const trimmed = w.trim();
            if (trimmed.length > 2 && !excludeWords.has(trimmed)) {
              const capitalized = trimmed.charAt(0).toUpperCase() + trimmed.slice(1);
              if (!localKeywords.includes(capitalized)) {
                localKeywords.push(capitalized);
              }
            }
          }
        }
      }
    }

    console.log(`Extracted local keywords: ${JSON.stringify(localKeywords)}`);

    let solved = false;
    for (const keyword of localKeywords) {
      const searchQuery = `${pt.brand}, ${keyword}, Malaysia`;
      console.log(`--> Trying query: "${searchQuery}"`);
      
      const geoData = await geocodeAddress(searchQuery);
      if (geoData.status === 'OK' && geoData.results && geoData.results.length > 0) {
        const loc = geoData.results[0].geometry.location;
        const distToMY = Math.abs(loc.lat - 4.210484) + Math.abs(loc.lng - 101.975766);
        
        if (distToMY > 0.5) { // not national center
          console.log(`✅ SUCCESS! Resolved to: ${geoData.results[0].formatted_address} (${loc.lat}, ${loc.lng})`);
          solved = true;
          break;
        } else {
          console.log(`❌ Result was just the national center of Malaysia.`);
        }
      } else {
        console.log(`❌ Query failed or returned empty.`);
      }
    }
    
    if (!solved) {
      console.log(`⚠️ Failed to resolve a local branch dynamically.`);
    }
  }
}

run();

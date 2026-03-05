#!/bin/bash
# Download podcast episodes via Apple Podcast directory + RSS
# Usage:
#   podcast.sh search "query"                     - Search for podcasts
#   podcast.sh episodes FEED_URL [limit]           - List episodes from RSS feed
#   podcast.sh download MP3_URL OUTPUT_PATH        - Download an episode
set -euo pipefail

case "${1:-}" in
  search)
    QUERY="${2:?Usage: podcast.sh search \"query\"}"
    curl -s "https://itunes.apple.com/search?term=$(node -e "console.log(encodeURIComponent(process.argv[1]))" "$QUERY")&media=podcast&limit=10" | node -e "
      let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{
        const r=JSON.parse(d);
        r.results.forEach((p,i)=>console.log((i+1)+'. '+p.collectionName+' | FEED: '+p.feedUrl));
        if(!r.results.length) console.log('No results found.');
      })"
    ;;

  episodes)
    FEED_URL="${2:?Usage: podcast.sh episodes FEED_URL [limit]}"
    LIMIT="${3:-10}"
    curl -sL "$FEED_URL" | node -e "
      let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{
        const items=d.match(/<item>[\s\S]*?<\/item>/g)||[];
        items.slice(0,parseInt(process.argv[1])).forEach((item,i)=>{
          const title=item.match(/<title>(?:<!\[CDATA\[)?(.*?)(?:\]\]>)?<\/title>/)?.[1]||'untitled';
          const url=item.match(/enclosure[^>]*url=\"([^\"]*)\"/)?.[1]||'no url';
          const date=item.match(/<pubDate>(.*?)<\/pubDate>/)?.[1]||'';
          console.log((i+1)+'. '+title);
          console.log('   Date: '+date);
          console.log('   URL: '+url);
          console.log('');
        });
      })" "$LIMIT"
    ;;

  download)
    URL="${2:?Usage: podcast.sh download MP3_URL OUTPUT_PATH}"
    OUTPUT="${3:?}"
    echo "Downloading to ${OUTPUT}..."
    curl -sL -o "$OUTPUT" "$URL"
    SIZE=$(ls -lh "$OUTPUT" | awk '{print $5}')
    echo "Done. Size: ${SIZE}"
    ;;

  *)
    echo "Usage: podcast.sh {search|episodes|download} [args...]"
    exit 1
    ;;
esac

const fetch = (...args) =>
  import('node-fetch').then(({default: fetch}) => fetch(...args));

async function test() {
  const res = await fetch("http://localhost:3000/drawings");
  const data = await res.json();
  console.log(data);
}

test();


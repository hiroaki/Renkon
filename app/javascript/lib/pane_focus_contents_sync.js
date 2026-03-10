export function getArticleContentsFrameMap(contentsFrame) {
  const frames = Array.from(contentsFrame.querySelectorAll('turbo-frame[data-article-id]'));
  return new Map(frames.map((frame) => [frame.dataset.articleId, frame]));
}

export function createArticleContentsFrame(articleId, contentUrl) {
  const frame = document.createElement('turbo-frame');
  frame.id = `contents-article-${articleId}`;
  frame.dataset.articleId = articleId;
  frame.dataset.cached = 'true';
  frame.src = contentUrl;
  return frame;
}

export function hideArticleContentsFrame(frame) {
  frame.hidden = true;
}

export function showArticleContentsFrame(frame) {
  frame.hidden = false;
}

export function syncContentsPaneBySelectedArticles(contentsFrame, selectedItems) {
  const selectedEntries = selectedItems
    .map((li) => {
      return {
        articleId: li.dataset.articleId,
        contentUrl: li.dataset.urlContent,
      };
    })
    .filter((entry) => entry.articleId && entry.contentUrl);

  const selectedIdSet = new Set(selectedEntries.map((entry) => entry.articleId));
  const existingById = getArticleContentsFrameMap(contentsFrame);

  existingById.forEach((frame, articleId) => {
    if (!selectedIdSet.has(articleId)) {
      hideArticleContentsFrame(frame);
    }
  });

  selectedEntries.forEach((entry) => {
    let frame = existingById.get(entry.articleId);
    if (!frame) {
      frame = createArticleContentsFrame(entry.articleId, entry.contentUrl);
    } else {
      console.debug('[contents-cache] reused', {
        articleId: entry.articleId,
        frameId: frame.id,
      });
    }

    showArticleContentsFrame(frame);
    contentsFrame.appendChild(frame);
  });
}

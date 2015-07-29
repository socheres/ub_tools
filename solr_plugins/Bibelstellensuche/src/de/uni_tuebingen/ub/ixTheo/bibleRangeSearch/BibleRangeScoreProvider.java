package de.uni_tuebingen.ub.ixTheo.bibleRangeSearch;

import java.io.IOException;

import org.apache.lucene.document.Document;
import org.apache.lucene.index.AtomicReaderContext;
import org.apache.lucene.index.IndexReader;
import org.apache.lucene.queries.CustomScoreProvider;

public class BibleRangeScoreProvider extends CustomScoreProvider {
	private final static float BEST_SCORE = Float.POSITIVE_INFINITY;
	private final static float NOT_RELEVANT = Float.NEGATIVE_INFINITY;

	private final Range[] ranges;

	public BibleRangeScoreProvider(final Range[] ranges, final AtomicReaderContext context) {
		super(context);
		this.ranges = ranges;
	}

	@Override
	public float customScore(final int docId, final float subQueryScore, final float valSrcScores[]) throws IOException {
		final IndexReader indexReader = this.context.reader();
		final Document doc = indexReader.document(docId);
		final String dbField = doc.get("bible_ranges");

		if (dbField == null || dbField.isEmpty()) {
			return NOT_RELEVANT;
		}

		final Range[] field_ranges = BibleRangeParser.getRangesFromDatabaseField(dbField);
		final int distance = Range.getDistance(field_ranges, ranges);
		return (distance == 0) ? BEST_SCORE : (1.0f / (float) distance);
	}
}
